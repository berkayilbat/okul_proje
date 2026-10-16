<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->phone)) {
    echo json_encode(["status" => "error", "message" => "Telefon numarasi gerekli."]);
    exit();
}

$phone = $data->phone;

try {
    $stmt = $conn->prepare("SELECT first_name, last_name, phone, address, professions, tax_no, company_name, tc_kimlik_no FROM users WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        echo json_encode(["status" => "success", "data" => $user]);
    } else {
        echo json_encode(["status" => "error", "message" => "Kullanici bulunamadi."]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Hata: " . $e->getMessage()]);
}
?>
