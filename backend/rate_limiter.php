<?php
// backend/rate_limiter.php

function safe_header($header_string) {
    if (!headers_sent()) {
        header($header_string);
    }
}

function safe_http_response_code($code) {
    if (!headers_sent()) {
        http_response_code($code);
    }
}

function get_client_ip() {
    if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
        return $_SERVER['HTTP_CLIENT_IP'];
    }
    if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
        return trim($ips[0]);
    }
    return $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
}

function init_rate_limit_table(PDO $conn) {
    static $initialized = false;
    if ($initialized) return;

    $sql = "CREATE TABLE IF NOT EXISTS `rate_limits` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `ip_address` VARCHAR(45) NOT NULL,
        `endpoint` VARCHAR(100) NOT NULL,
        `hits` INT DEFAULT 1,
        `first_hit_at` INT NOT NULL,
        `blocked_until` INT DEFAULT 0,
        UNIQUE KEY `ip_endpoint` (`ip_address`, `endpoint`),
        INDEX `idx_blocked` (`blocked_until`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";

    try {
        $conn->exec($sql);
        $initialized = true;
    } catch (Exception $e) {
        // Hata durumunda akışın kesilmemesi için sessiz devam edilir
    }
}

/**
 * Belirtilen uç nokta için istemci IP adresine göre hız sınırı (rate limit) uygular.
 *
 * @param PDO $conn Veritabanı bağlantısı
 * @param string $endpoint Kontrol edilen uç nokta (örn: 'login', 'register')
 * @param int $max_requests Zaman penceresindeki izin verilen maksimum istek sayısı
 * @param int $window_seconds Pencere süresi (saniye)
 * @param int $block_seconds Sınır aşıldığında uygulanacak engelleme süresi (saniye)
 */
function apply_rate_limit(PDO $conn, $endpoint, $max_requests = 60, $window_seconds = 60, $block_seconds = 60) {
    init_rate_limit_table($conn);

    $ip = get_client_ip();
    $now = time();

    try {
        $stmt = $conn->prepare("SELECT hits, first_hit_at, blocked_until FROM rate_limits WHERE ip_address = ? AND endpoint = ?");
        $stmt->execute([$ip, $endpoint]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row) {
            $blocked_until = (int)$row['blocked_until'];
            $first_hit_at = (int)$row['first_hit_at'];
            $hits = (int)$row['hits'];

            // 1. İstemci şu an engelli mi?
            if ($blocked_until > $now) {
                $retry_after = $blocked_until - $now;
                safe_http_response_code(429);
                safe_header("Retry-After: $retry_after");
                safe_header("X-RateLimit-Limit: $max_requests");
                safe_header("X-RateLimit-Remaining: 0");
                safe_header("X-RateLimit-Reset: $blocked_until");
                echo json_encode([
                    "status" => "error",
                    "code" => 429,
                    "is_rate_limited" => true,
                    "retry_after" => $retry_after,
                    "message" => "Çok fazla istek gönderdiniz. Lütfen {$retry_after} saniye sonra tekrar deneyiniz."
                ], JSON_UNESCAPED_UNICODE);
                exit();
            }

            // 2. Zaman penceresi dolmuş mu? (Pencereyi sıfırla)
            if (($now - $first_hit_at) > $window_seconds) {
                $upd = $conn->prepare("UPDATE rate_limits SET hits = 1, first_hit_at = ?, blocked_until = 0 WHERE ip_address = ? AND endpoint = ?");
                $upd->execute([$now, $ip, $endpoint]);
                $remaining = $max_requests - 1;
                safe_header("X-RateLimit-Limit: $max_requests");
                safe_header("X-RateLimit-Remaining: " . max(0, $remaining));
                safe_header("X-RateLimit-Reset: " . ($now + $window_seconds));
                return;
            }

            // 3. Pencere içinde limit aşıldı mı? (Yeni blok koy)
            if ($hits >= $max_requests) {
                $block_until_time = $now + $block_seconds;
                $upd = $conn->prepare("UPDATE rate_limits SET blocked_until = ? WHERE ip_address = ? AND endpoint = ?");
                $upd->execute([$block_until_time, $ip, $endpoint]);

                safe_http_response_code(429);
                safe_header("Retry-After: $block_seconds");
                safe_header("X-RateLimit-Limit: $max_requests");
                safe_header("X-RateLimit-Remaining: 0");
                safe_header("X-RateLimit-Reset: $block_until_time");
                echo json_encode([
                    "status" => "error",
                    "code" => 429,
                    "is_rate_limited" => true,
                    "retry_after" => $block_seconds,
                    "message" => "Çok fazla istek gönderdiniz. Lütfen {$block_seconds} saniye sonra tekrar deneyiniz."
                ], JSON_UNESCAPED_UNICODE);
                exit();
            }

            // 4. İzin verilen limit dahilinde, sayacı artır
            $upd = $conn->prepare("UPDATE rate_limits SET hits = hits + 1 WHERE ip_address = ? AND endpoint = ?");
            $upd->execute([$ip, $endpoint]);
            $remaining = $max_requests - ($hits + 1);
            safe_header("X-RateLimit-Limit: $max_requests");
            safe_header("X-RateLimit-Remaining: " . max(0, $remaining));
            safe_header("X-RateLimit-Reset: " . ($first_hit_at + $window_seconds));

        } else {
            // İlk istek kaydı
            $ins = $conn->prepare("INSERT INTO rate_limits (ip_address, endpoint, hits, first_hit_at, blocked_until) VALUES (?, ?, 1, ?, 0)");
            $ins->execute([$ip, $endpoint, $now]);

            $remaining = $max_requests - 1;
            safe_header("X-RateLimit-Limit: $max_requests");
            safe_header("X-RateLimit-Remaining: " . max(0, $remaining));
            safe_header("X-RateLimit-Reset: " . ($now + $window_seconds));
        }

    } catch (Exception $e) {
        // Sessiz devam et
    }
}

/**
 * Test veya sıfırlama amaçlı belirli bir IP veya endpoint'in limitini sıfırlar.
 */
function reset_rate_limit(PDO $conn, $ip = null, $endpoint = null) {
    init_rate_limit_table($conn);
    try {
        if ($ip && $endpoint) {
            $stmt = $conn->prepare("DELETE FROM rate_limits WHERE ip_address = ? AND endpoint = ?");
            $stmt->execute([$ip, $endpoint]);
        } elseif ($endpoint) {
            $stmt = $conn->prepare("DELETE FROM rate_limits WHERE endpoint = ?");
            $stmt->execute([$endpoint]);
        } elseif ($ip) {
            $stmt = $conn->prepare("DELETE FROM rate_limits WHERE ip_address = ?");
            $stmt->execute([$ip]);
        } else {
            $conn->exec("TRUNCATE TABLE rate_limits");
        }
    } catch (Exception $e) {}
}
?>
