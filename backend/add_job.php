<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->employer_phone) || !isset($data->title) || !isset($data->location) || !isset($data->wage) || !isset($data->dates)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$employer_phone = $data->employer_phone;
$title = $data->title;
$location = $data->location;
$working_hours = isset($data->working_hours) ? $data->working_hours : '';
$wage = $data->wage;
$description = isset($data->description) ? $data->description : '';
$dates = $data->dates;
$status = 'open';

$stmt = $conn->prepare("INSERT INTO jobs (employer_phone, title, location, working_hours, wage, description, dates, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

try {
    $stmt->execute([$employer_phone, $title, $location, $working_hours, $wage, $description, $dates, $status]);
    echo json_encode(["status" => "success", "message" => "İlan başarıyla yayınlandı."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İlan eklenirken hata oluştu: " . $e->getMessage()]);
}
?>
