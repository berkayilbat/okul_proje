<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 5 istek / 300 saniye (Aşılırsa 180 sn blok)
apply_rate_limit($conn, 'register', 5, 300, 180);

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

$role = sanitize_enum($data->role, ['Employer', 'Employee'], 'Employee');
$first_name = sanitize_text($data->first_name, 100);
$last_name = sanitize_text($data->last_name, 100);
$phone = sanitize_phone($data->phone);
$password = password_hash((string)$data->password, PASSWORD_BCRYPT); 
$tc_kimlik_no = isset($data->tc_kimlik_no) ? sanitize_text($data->tc_kimlik_no, 11) : null;
$company_name = isset($data->company_name) ? sanitize_text($data->company_name, 150) : null;
$tax_no = isset($data->tax_no) ? sanitize_text($data->tax_no, 10) : null;

if (empty($first_name) || empty($last_name) || empty($phone)) {
    echo json_encode(["status" => "error", "message" => "Ad, soyad ve telefon alanları zorunludur."]);
    exit();
}

if ($role === 'Employer') {
    if (empty($tax_no)) {
        echo json_encode(["status" => "error", "message" => "İşveren için Vergi Kimlik Numarası zorunludur."]);
        exit();
    }
    if (!is_valid_vkn($tax_no)) {
        echo json_encode(["status" => "error", "message" => "Vergi Kimlik Numarası algoritmaya uymuyor (10 haneli VKN olmalıdır)."]);
        exit();
    }
}

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