<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->job_id) || !isset($data->employee_phone)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$job_id = $data->job_id;
$employee_phone = $data->employee_phone;

// Check if already applied
$checkStmt = $conn->prepare("SELECT id FROM job_applications WHERE job_id = ? AND employee_phone = ?");
$checkStmt->execute([$job_id, $employee_phone]);

if ($checkStmt->rowCount() > 0) {
    echo json_encode(["status" => "error", "message" => "Bu ilana zaten başvurdunuz."]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO job_applications (job_id, employee_phone, status) VALUES (?, ?, 'applied')");

try {
    $stmt->execute([$job_id, $employee_phone]);
    echo json_encode(["status" => "success", "message" => "Başvurunuz alındı."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Başvuru sırasında hata oluştu: " . $e->getMessage()]);
}
?>
