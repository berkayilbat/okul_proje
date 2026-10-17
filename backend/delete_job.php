<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->job_id)) {
    echo json_encode(["status" => "error", "message" => "İlan ID eksik."]);
    exit();
}

$job_id = intval($data->job_id);

try {
    // Önce bu ilana ait başvuruları temizle
    $deleteApps = $conn->prepare("DELETE FROM job_applications WHERE job_id = ?");
    $deleteApps->execute([$job_id]);

    // İlanı sil
    $deleteJob = $conn->prepare("DELETE FROM jobs WHERE id = ?");
    $deleteJob->execute([$job_id]);

    echo json_encode(["status" => "success", "message" => "İlan başarıyla silindi."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İlan silinirken bir hata oluştu: " . $e->getMessage()]);
}
?>
