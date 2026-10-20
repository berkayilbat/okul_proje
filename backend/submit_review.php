<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 10 istek / 60 saniye
apply_rate_limit($conn, 'submit_review', 10, 60, 60);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->application_id) || !isset($data->rating)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$application_id = intval($data->application_id);
$rating = intval($data->rating);
$comment = isset($data->comment) ? sanitize_input($data->comment) : '';

try {
    // 1. job_applications tablosunda çalışana verilen puan ve yorumu güncelle
    $stmt = $conn->prepare("UPDATE job_applications SET rating = ?, review_comment = ? WHERE id = ?");
    $stmt->execute([$rating, $comment, $application_id]);

    // 2. Başvurudan çalışanın telefonunu bul
    $appStmt = $conn->prepare("SELECT employee_phone FROM job_applications WHERE id = ?");
    $appStmt->execute([$application_id]);
    $app = $appStmt->fetch(PDO::FETCH_ASSOC);

    if ($app) {
        $employee_phone = $app['employee_phone'];

        // 3. Çalışanın tüm puanlarının ortalamasını hesapla
        $avgStmt = $conn->prepare("
            SELECT AVG(rating) as avg_rating 
            FROM job_applications 
            WHERE employee_phone = ? AND rating IS NOT NULL AND rating > 0
        ");
        $avgStmt->execute([$employee_phone]);
        $row = $avgStmt->fetch(PDO::FETCH_ASSOC);

        if ($row && $row['avg_rating'] !== null) {
            $newAvg = round(floatval($row['avg_rating']), 2);
            $userUpdate = $conn->prepare("UPDATE users SET average_rating = ? WHERE phone = ?");
            $userUpdate->execute([$newAvg, $employee_phone]);
        }
    }

    echo json_encode(["status" => "success", "message" => "Çalışan değerlendirmesi başarıyla kaydedildi."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Değerlendirme kaydedilirken hata: " . $e->getMessage()]);
}
?>
