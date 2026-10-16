<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");
header("X-XSS-Protection: 1; mode=block");

$host = 'localhost';
$db_name = 'my_app_db';
$username = 'root';
$password = '';

try {
    $conn = new PDO("mysql:host={$host};dbname={$db_name};charset=utf8mb4", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(["status" => "error", "message" => "Veritabanı bağlantısı kurulamadı."]);
    exit();
}

function sanitize_input($data) {
    if (is_null($data)) return null;
    return htmlspecialchars(trim((string)$data), ENT_QUOTES, 'UTF-8');
}
?>
