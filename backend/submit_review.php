<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->application_id) || !isset($data->rating)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre."]);
    exit();
}

echo json_encode(["status" => "success", "message" => "Değerlendirme başarıyla kaydedildi."]);
?>
