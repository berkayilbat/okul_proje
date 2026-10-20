<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 20 istek / 60 saniye
apply_rate_limit($conn, 'update_profile', 20, 60, 60);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->old_phone) || !isset($data->phone)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$old_phone = sanitize_phone($data->old_phone);
$phone = sanitize_phone($data->phone);

if (empty($old_phone) || empty($phone)) {
    echo json_encode(["status" => "error", "message" => "Geçerli bir telefon numarası girilmelidir."]);
    exit();
}

$first_name = isset($data->first_name) ? sanitize_text($data->first_name, 100) : null;
$last_name = isset($data->last_name) ? sanitize_text($data->last_name, 100) : null;
$address = isset($data->address) ? sanitize_text($data->address, 255) : null;
$professions = isset($data->professions) ? sanitize_text($data->professions, 255) : null;
$tax_no = isset($data->tax_no) ? sanitize_text($data->tax_no, 10) : null;

if ($tax_no !== null && $tax_no !== '') {
    if (!is_valid_vkn($tax_no)) {
        echo json_encode(["status" => "error", "message" => "Vergi Kimlik Numarası algoritmaya uymuyor (10 haneli VKN olmalıdır)."]);
        exit();
    }
}

try {
    $stmt = $conn->prepare("
        UPDATE users 
        SET phone = ?, 
            first_name = COALESCE(?, first_name), 
            last_name = COALESCE(?, last_name), 
            address = COALESCE(?, address), 
            professions = COALESCE(?, professions), 
            tax_no = COALESCE(?, tax_no) 
        WHERE phone = ?
    ");
    $stmt->execute([$phone, $first_name, $last_name, $address, $professions, $tax_no, $old_phone]);

    echo json_encode(["status" => "success", "message" => "Profil güncellendi."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Güncelleme hatası: " . $e->getMessage()]);
}
?>