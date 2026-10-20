<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 10 istek / 60 saniye
apply_rate_limit($conn, 'submit_employer_review', 10, 60, 60);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->application_id) || !isset($data->rating)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$application_id = sanitize_int($data->application_id, 0, 1);
$rating = sanitize_int($data->rating, 5, 1, 5);
$comment = isset($data->comment) ? sanitize_text($data->comment, 1000) : '';

if ($application_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Geçersiz başvuru ID."]);
    exit();
}

try {
    // 1. job_applications tablosunda işverene verilen puan ve yorumu güncelle
    $stmt = $conn->prepare("UPDATE job_applications SET employer_rating = ?, employer_review_comment = ? WHERE id = ?");
    $stmt->execute([$rating, $comment, $application_id]);

    // 2. Başvurudan işverenin telefonunu bul (jobs tablosu üzerinden)
    $appStmt = $conn->prepare("
        SELECT j.employer_phone 
        FROM job_applications ja 
        JOIN jobs j ON ja.job_id = j.id 
        WHERE ja.id = ?
    ");
    $appStmt->execute([$application_id]);
    $job = $appStmt->fetch(PDO::FETCH_ASSOC);

    if ($job) {
        $employer_phone = $job['employer_phone'];

        // 3. İşverenin aldığı tüm puanların ortalamasını hesapla
        $avgStmt = $conn->prepare("
            SELECT AVG(ja.employer_rating) as avg_rating 
            FROM job_applications ja
            JOIN jobs j ON ja.job_id = j.id
            WHERE j.employer_phone = ? AND ja.employer_rating IS NOT NULL AND ja.employer_rating > 0
        ");
        $avgStmt->execute([$employer_phone]);
        $row = $avgStmt->fetch(PDO::FETCH_ASSOC);

        if ($row && $row['avg_rating'] !== null) {
            $newAvg = round(floatval($row['avg_rating']), 2);
            $userUpdate = $conn->prepare("UPDATE users SET average_rating = ? WHERE phone = ?");
            $userUpdate->execute([$newAvg, $employer_phone]);
        }
    }

    echo json_encode(["status" => "success", "message" => "İşveren değerlendirmesi başarıyla kaydedildi."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Değerlendirme kaydedilirken hata: " . $e->getMessage()]);
}
?>