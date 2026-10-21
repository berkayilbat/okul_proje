<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 20 istek / 60 saniye
apply_rate_limit($conn, 'update_job', 20, 60, 60);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->job_id) || !isset($data->employer_phone) || !isset($data->title) || !isset($data->location) || !isset($data->wage) || !isset($data->dates)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$job_id = sanitize_int($data->job_id, 0, 1);
$employer_phone = sanitize_phone($data->employer_phone);
$title = sanitize_text($data->title, 150);
$location = sanitize_text($data->location, 100);
$working_hours = isset($data->working_hours) ? sanitize_text($data->working_hours, 50) : '';
$wage = sanitize_float($data->wage, 0.0, 0.0);
$description = isset($data->description) ? sanitize_text($data->description, 2000) : '';
$dates = sanitize_text($data->dates, 100);
$worker_count = isset($data->worker_count) ? max(1, min(100, (int)$data->worker_count)) : null;

if ($job_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Geçersiz ilan ID."]);
    exit();
}

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

try {
    // İlanın varlığını ve işverene ait olduğunu doğrula
    $checkStmt = $conn->prepare("SELECT id, employer_phone, status, worker_count FROM jobs WHERE id = ?");
    $checkStmt->execute([$job_id]);
    $existingJob = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$existingJob) {
        echo json_encode(["status" => "error", "message" => "Düzenlenecek ilan bulunamadı."]);
        exit();
    }

    if ($existingJob['employer_phone'] !== $employer_phone) {
        echo json_encode(["status" => "error", "message" => "Bu ilanı düzenleme yetkiniz bulunmuyor."]);
        exit();
    }

    if ($existingJob['status'] !== 'open') {
        echo json_encode(["status" => "error", "message" => "Yalnızca açık durumdaki ilanlar düzenlenebilir."]);
        exit();
    }

    // Eğer yeni worker_count belirtilmişse, onaylanmış çalışan sayısından az olamaz
    if ($worker_count !== null) {
        $countStmt = $conn->prepare("SELECT COUNT(*) FROM job_applications WHERE job_id = ? AND status IN ('accepted', 'in_progress', 'completed')");
        $countStmt->execute([$job_id]);
        $activeCount = (int)$countStmt->fetchColumn();
        if ($worker_count < $activeCount) {
            echo json_encode(["status" => "error", "message" => "Kontenjan, halihazırda onaylanmış çalışan sayısından ($activeCount) az olamaz."]);
            exit();
        }
    }

    $stmt = $conn->prepare("
        UPDATE jobs 
        SET title = ?, 
            location = ?, 
            working_hours = ?, 
            wage = ?, 
            description = ?, 
            dates = ?,
            worker_count = COALESCE(?, worker_count)
        WHERE id = ? AND employer_phone = ?
    ");
    $stmt->execute([$title, $location, $working_hours, $wage, $description, $dates, $worker_count, $job_id, $employer_phone]);

    echo json_encode(["status" => "success", "message" => "İlan başarıyla güncellendi."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İlan güncellenirken bir sorun oluştu: " . $e->getMessage()]);
}
?>