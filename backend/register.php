<?php
require_once 'db.php';

// Sadece POST destekleniyor
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

// JSON olarak gelen parametreleri okuyalım
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

$role = $data->role;
$first_name = $data->first_name;
$last_name = $data->last_name;
$phone = $data->phone;
// Gerçek projede bunu password_hash() ile şifrelemeliyiz. Şimdilik Flutter tarafından düz geldiği şekilde kaydediyoruz.
$password = $data->password; 
$tc_kimlik_no = isset($data->tc_kimlik_no) ? $data->tc_kimlik_no : null;
$company_name = isset($data->company_name) ? $data->company_name : null;
$tax_no = isset($data->tax_no) ? $data->tax_no : null;

// Telefon numarasını kopyalamaya karşı kontrol edelim (Eğer isterseniz)
$checkStmt = $conn->prepare("SELECT id FROM users WHERE phone = ?");
$checkStmt->execute([$phone]);
if ($checkStmt->rowCount() > 0) {
    echo json_encode(["status" => "error", "message" => "Bu telefon numarası ile zaten kayıtlı bir kullanıcı var."]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO users (role, first_name, last_name, phone, password, tc_kimlik_no, company_name, tax_no) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

try {
    $stmt->execute([$role, $first_name, $last_name, $phone, $password, $tc_kimlik_no, $company_name, $tax_no]);
    echo json_encode(["status" => "success", "message" => "Kayıt başarıyla tamamlandı."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Kayıt sırasında hata oluştu: " . $e->getMessage()]);
}
?>
