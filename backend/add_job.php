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

$employer_phone = sanitize_input($data->employer_phone);
$title = sanitize_input($data->title);
$location = sanitize_input($data->location);
$working_hours = isset($data->working_hours) ? sanitize_input($data->working_hours) : '';
$wage = sanitize_input($data->wage);
$description = isset($data->description) ? sanitize_input($data->description) : '';
$dates = sanitize_input($data->dates);
$status = 'open';

$stmt = $conn->prepare("INSERT INTO jobs (employer_phone, title, location, working_hours, wage, description, dates, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

try {
    $stmt->execute([$employer_phone, $title, $location, $working_hours, $wage, $description, $dates, $status]);
    echo json_encode(["status" => "success", "message" => "İlan başarıyla yayınlandı."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İlan yayınlanırken bir sorun oluştu. Lütfen tekrar deneyin."]);
}
?>
