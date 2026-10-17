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

$phone = sanitize_input($data->phone);
$role = sanitize_input($data->role);

if ($role !== 'Employer' && $role !== 'Employee') {
    echo json_encode(["status" => "error", "message" => "Geçersiz rol seçimi. Rol Employer veya Employee olmalıdır."]);
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
