<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->phone) || !isset($data->password)) {
    echo json_encode(["status" => "error", "message" => "Lütfen telefon ve şifrenizi girin."]);
    exit();
}

$phone = sanitize_input($data->phone);
$password = $data->password;

if (session_status() === PHP_SESSION_NONE) {
    @session_start();
}
$ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
$attemptsKey = 'login_attempts_' . md5($ip . '_' . $phone);
$timeKey = 'login_time_' . md5($ip . '_' . $phone);

$attempts = $_SESSION[$attemptsKey] ?? 0;
$lastAttemptTime = $_SESSION[$timeKey] ?? 0;

if ($attempts >= 5 && (time() - $lastAttemptTime) < 60) {
    echo json_encode(["status" => "error", "message" => "Çok fazla hatalı giriş denemesi. Lütfen 1 dakika sonra tekrar deneyin."]);
    exit();
}

if ((time() - $lastAttemptTime) >= 60) {
    $_SESSION[$attemptsKey] = 0;
    $attempts = 0;
}

$stmt = $conn->prepare("SELECT * FROM users WHERE phone = ? LIMIT 1");
$stmt->execute([$phone]);

if ($stmt->rowCount() > 0) {
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $isPasswordValid = password_verify($password, $user['password']) || ($password === $user['password']);
    
    if ($isPasswordValid) {
        $_SESSION[$attemptsKey] = 0;
        unset($user['password']);
        echo json_encode([
            "status" => "success", 
            "message" => "Giriş başarılı.", 
            "user" => $user
        ]);
    } else {
        $_SESSION[$attemptsKey] = $attempts + 1;
        $_SESSION[$timeKey] = time();
        echo json_encode(["status" => "error", "message" => "Şifre hatalı."]);
    }
} else {
    $_SESSION[$attemptsKey] = $attempts + 1;
    $_SESSION[$timeKey] = time();
    echo json_encode(["status" => "error", "message" => "Kullanıcı bulunamadı."]);
}
?>
