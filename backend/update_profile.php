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

$old_phone = $data->old_phone;
$phone = $data->phone;
$first_name = isset($data->first_name) ? $data->first_name : null;
$last_name = isset($data->last_name) ? $data->last_name : null;
$address = isset($data->address) ? $data->address : null;
$professions = isset($data->professions) ? $data->professions : null;
$tax_no = isset($data->tax_no) ? $data->tax_no : null;

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
