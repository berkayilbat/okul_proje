<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 10 istek / 60 saniye
apply_rate_limit($conn, 'add_job', 10, 60, 60);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->employer_phone) || !isset($data->title) || !isset($data->location) || !isset($data->wage) || !isset($data->dates)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$employer_phone = sanitize_phone($data->employer_phone);
$title = sanitize_text($data->title, 150);
$location = sanitize_text($data->location, 100);
$working_hours = isset($data->working_hours) ? sanitize_text($data->working_hours, 50) : '';
$wage = sanitize_float($data->wage, 0.0, 0.0);
$description = isset($data->description) ? sanitize_text($data->description, 2000) : '';
$dates = sanitize_text($data->dates, 100);
$worker_count = isset($data->worker_count) ? max(1, min(100, (int)$data->worker_count)) : 1;
$status = 'open';

if (empty($employer_phone)) {
    echo json_encode(["status" => "error", "message" => "Geçerli bir işveren telefon numarası gereklidir."]);
    exit();
}

if (empty($title)) {
    echo json_encode(["status" => "error", "message" => "İlan başlığı boş olamaz."]);
    exit();
}

if ($wage <= 0) {
    echo json_encode(["status" => "error", "message" => "Yevmiye tutarı sıfırdan büyük olmalıdır."]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO jobs (employer_phone, title, location, working_hours, wage, description, dates, worker_count, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");

try {
    $stmt->execute([$employer_phone, $title, $location, $working_hours, $wage, $description, $dates, $worker_count, $status]);
    echo json_encode(["status" => "success", "message" => "İlan başarıyla yayınlandı."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İlan yayınlanırken bir sorun oluştu. Lütfen tekrar deneyin."]);
}
?>