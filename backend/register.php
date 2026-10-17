<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (
    !isset($data->role) || 
    !isset($data->first_name) || 
    !isset($data->last_name) || 
    !isset($data->phone) || 
    !isset($data->password)
) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$role = sanitize_input($data->role);
$first_name = sanitize_input($data->first_name);
$last_name = sanitize_input($data->last_name);
$phone = sanitize_input($data->phone);
$password = password_hash($data->password, PASSWORD_BCRYPT); 
$tc_kimlik_no = isset($data->tc_kimlik_no) ? sanitize_input($data->tc_kimlik_no) : null;
$company_name = isset($data->company_name) ? sanitize_input($data->company_name) : null;
$tax_no = isset($data->tax_no) ? sanitize_input($data->tax_no) : null;

$altPhone = (strpos($phone, '0') === 0 && strlen($phone) === 11) ? substr($phone, 1) : ('0' . $phone);
$checkStmt = $conn->prepare("SELECT id FROM users WHERE phone = ? OR phone = ?");
$checkStmt->execute([$phone, $altPhone]);
if ($checkStmt->rowCount() > 0) {
    echo json_encode(["status" => "error", "message" => "Bu telefon numarası ile zaten kayıtlı bir kullanıcı var."]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO users (role, first_name, last_name, phone, password, tc_kimlik_no, company_name, tax_no) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

try {
    $stmt->execute([$role, $first_name, $last_name, $phone, $password, $tc_kimlik_no, $company_name, $tax_no]);
    echo json_encode(["status" => "success", "message" => "Kayıt başarıyla tamamlandı."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Kayıt işlemi gerçekleştirilemedi. Lütfen tekrar deneyin."]);
}
?>
