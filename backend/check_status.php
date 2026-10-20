<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->application_id)) {
    echo json_encode(["status" => "error", "message" => "Eksik başvuru id."]);
    exit();
}

$application_id = sanitize_int($data->application_id, 0, 1);
if ($application_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Geçersiz başvuru id."]);
    exit();
}

try {
    $stmt = $conn->prepare("SELECT status FROM job_applications WHERE id = ?");
    $stmt->execute([$application_id]);
    $app = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($app) {
        echo json_encode(["status" => "success", "data" => ["status" => $app['status']]]);
    } else {
        echo json_encode(["status" => "error", "message" => "Başvuru bulunamadı."]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Hata: " . $e->getMessage()]);
}
?>