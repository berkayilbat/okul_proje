<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Access-Control-Request-Private-Network");
header("Access-Control-Allow-Private-Network: true");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json; charset=UTF-8");
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");
header("X-XSS-Protection: 1; mode=block");
header("Content-Security-Policy: default-src 'none'; frame-ancestors 'none';");

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$db_name = 'my_app_db';
$username = 'root';

// XAMPP (Windows) şifresiz, MAMP (macOS) 'root' şifresi veya farklı port kullanabilir.
$conn = null;
$last_db_err = '';

$configs = [
    // 1. Standart XAMPP (Port 3306, şifresiz)
    ['dsn' => "mysql:host=127.0.0.1;port=3306;charset=utf8mb4", 'pass' => ''],
    // 2. Standart MAMP (Port 3306, şifre: 'root')
    ['dsn' => "mysql:host=127.0.0.1;port=3306;charset=utf8mb4", 'pass' => 'root'],
    // 3. MAMP Varsayılan Port (Port 8889, şifre: 'root')
    ['dsn' => "mysql:host=127.0.0.1;port=8889;charset=utf8mb4", 'pass' => 'root'],
    // 4. MAMP Unix Socket
    ['dsn' => "mysql:unix_socket=/Applications/MAMP/tmp/mysql/mysql.sock;charset=utf8mb4", 'pass' => 'root'],
];

foreach ($configs as $cfg) {
    try {
        $tempConn = new PDO($cfg['dsn'], $username, $cfg['pass']);
        $tempConn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        // Gerçek prepared statements zorunluluğu (SQL Injection koruması)
        $tempConn->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
        $tempConn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $tempConn->exec("CREATE DATABASE IF NOT EXISTS `{$db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
        $tempConn->exec("USE `{$db_name}`;");
        $conn = $tempConn;
        break;
    } catch (PDOException $e) {
        $last_db_err = $e->getMessage();
    }
}

if (!$conn) {
    echo json_encode(["status" => "error", "message" => "Veritabanı bağlantısı kurulamadı: " . $last_db_err]);
    exit();
}

/**
 * Metin girdilerini XSS ve kontrol karakterlerinden arındırır.
 */
function sanitize_text($data, $maxLen = null) {
    if (is_null($data)) return null;
    $str = (string)$data;
    // Null byte temizleme
    $str = str_replace(chr(0), '', $str);
    // Boşluk kırpma
    $str = trim($str);
    // HTML etiketlerini ayıkla
    $str = strip_tags($str);
    // Özel HTML karakterlerini güvenli entity'e dönüştür
    $str = htmlspecialchars($str, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    if ($maxLen !== null && $maxLen > 0) {
        $str = mb_substr($str, 0, $maxLen, 'UTF-8');
    }
    return $str;
}

/**
 * Geriye dönük uyumluluk için temel sanitization wrapper'ı.
 */
function sanitize_input($data) {
    return sanitize_text($data);
}

/**
 * Tamsayı değerleri doğrular ve sınırlandırır.
 */
function sanitize_int($data, $default = 0, $min = null, $max = null) {
    if ($data === null || $data === '') return $default;
    $filtered = filter_var($data, FILTER_VALIDATE_INT);
    if ($filtered === false) return $default;
    if ($min !== null && $filtered < $min) return $min;
    if ($max !== null && $filtered > $max) return $max;
    return (int)$filtered;
}

/**
 * Ondalıklı/ücret değerlerini doğrular ve float tipine dönüştürür.
 */
function sanitize_float($data, $default = 0.0, $min = null, $max = null) {
    if ($data === null || $data === '') return $default;
    $cleaned = str_replace(',', '.', trim((string)$data));
    $filtered = filter_var($cleaned, FILTER_VALIDATE_FLOAT);
    if ($filtered === false) return $default;
    if ($min !== null && $filtered < $min) return $min;
    if ($max !== null && $filtered > $max) return $max;
    return (float)$filtered;
}

/**
 * Telefon numarasını sadece rakamlardan oluşacak şekilde temizler.
 */
function sanitize_phone($data) {
    if (is_null($data)) return '';
    $digits = preg_replace('/\D/', '', (string)$data);
    return trim($digits);
}

/**
 * Değeri izin verilen beyaz liste (whitelist) içinden doğrular.
 */
function sanitize_enum($data, array $allowed, $default = null) {
    if (is_null($data)) return $default;
    $val = trim((string)$data);
    return in_array($val, $allowed, true) ? $val : $default;
}

/**
 * Vergi Kimlik Numarası (VKN) algoritma kontrolü (10 haneli).
 */
function is_valid_vkn($vkn) {
    if (empty($vkn)) return false;
    $vkn = trim((string)$vkn);
    if (strlen($vkn) !== 10 || !ctype_digit($vkn)) return false;

    $sum = 0;
    $last_digit = (int)$vkn[9];

    for ($i = 0; $i < 9; $i++) {
        $digit = (int)$vkn[$i];
        $weight = 9 - $i;
        $v1 = ($digit + $weight) % 10;
        if ($v1 !== 0) {
            $v2 = ($v1 * (1 << $weight)) % 9;
            if ($v2 === 0) $v2 = 9;
            $sum += $v2;
        }
    }

    $calc = (10 - ($sum % 10)) % 10;
    return $calc === $last_digit;
}

require_once __DIR__ . '/rate_limiter.php';
?>