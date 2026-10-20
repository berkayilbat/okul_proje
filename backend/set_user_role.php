<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->phone) || !isset($data->role)) {
    echo json_encode(["status" => "error", "message" => "Telefon ve rol parametreleri gereklidir."]);
    exit();
}

$phone = sanitize_phone($data->phone);
$role = sanitize_enum($data->role, ['Employer', 'Employee'], null);

if (empty($phone) || $role === null) {
    echo json_encode(["status" => "error", "message" => "Geçersiz rol veya telefon seçimi."]);
    exit();
}

try {
    $stmt = $conn->prepare("UPDATE users SET role = ? WHERE phone = ?");
    $stmt->execute([$role, $phone]);

    echo json_encode([
        "status" => "success", 
        "message" => "Kullanıcı rolü başarıyla güncellendi.",
        "role" => $role
    ]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Rol güncellenirken hata oluştu: " . $e->getMessage()]);
}
?>