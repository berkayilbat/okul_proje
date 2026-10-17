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
    ['dsn' => "mysql:host=127.0.0.1;port=3306;dbname={$db_name};charset=utf8mb4", 'pass' => ''],
    // 2. Standart MAMP (Port 3306, şifre: 'root')
    ['dsn' => "mysql:host=127.0.0.1;port=3306;dbname={$db_name};charset=utf8mb4", 'pass' => 'root'],
    // 3. MAMP Varsayılan Port (Port 8889, şifre: 'root')
    ['dsn' => "mysql:host=127.0.0.1;port=8889;dbname={$db_name};charset=utf8mb4", 'pass' => 'root'],
    // 4. MAMP Unix Socket
    ['dsn' => "mysql:unix_socket=/Applications/MAMP/tmp/mysql/mysql.sock;dbname={$db_name};charset=utf8mb4", 'pass' => 'root'],
];

foreach ($configs as $cfg) {
    try {
        $conn = new PDO($cfg['dsn'], $username, $cfg['pass']);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        break;
    } catch (PDOException $e) {
        $last_db_err = $e->getMessage();
    }
}

if (!$conn) {
    echo json_encode(["status" => "error", "message" => "Veritabanı bağlantısı kurulamadı: " . $last_db_err]);
    exit();
}

function sanitize_input($data) {
    if (is_null($data)) return null;
    return htmlspecialchars(trim((string)$data), ENT_QUOTES, 'UTF-8');
}
?>
