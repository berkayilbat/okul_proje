<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

// action = 'accept', 'reject', 'complete'
if (!isset($data->application_id) || !isset($data->action)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$application_id = $data->application_id;
$action = $data->action;

try {
    // Statüleri işle
    if ($action === 'accept') {
        $stmt = $conn->prepare("UPDATE job_applications SET status = 'accepted' WHERE id = ?");
        $stmt->execute([$application_id]);
        echo json_encode(["status" => "success", "message" => "Başvuru kabul edildi."]);
    } else if ($action === 'reject') {
        $stmt = $conn->prepare("UPDATE job_applications SET status = 'rejected' WHERE id = ?");
        $stmt->execute([$application_id]);
        echo json_encode(["status" => "success", "message" => "Başvuru reddedildi."]);
    } else if ($action === 'start_work') {
        $stmt = $conn->prepare("UPDATE job_applications SET status = 'in_progress' WHERE id = ?");
        $stmt->execute([$application_id]);
        echo json_encode(["status" => "success", "message" => "Çalışma Başarıyla Başlatıldı!"]);
    } else if ($action === 'complete') {
        // İşi bitirme ve parayı aktarma işlemi
        $appStmt = $conn->prepare("SELECT job_id, employee_phone FROM job_applications WHERE id = ?");
        $appStmt->execute([$application_id]);
        $application = $appStmt->fetch(PDO::FETCH_ASSOC);

        if ($application) {
            $job_id = $application['job_id'];
            $employee_phone = $application['employee_phone'];

            // İlandan parayı (wage) getir
            $jobStmt = $conn->prepare("SELECT wage FROM jobs WHERE id = ?");
            $jobStmt->execute([$job_id]);
            $job = $jobStmt->fetch(PDO::FETCH_ASSOC);

            if ($job) {
                $wage = floatval($job['wage']);
                
                // Çalışanın cüzdanına ekle
                $walletStmt = $conn->prepare("UPDATE users SET wallet_balance = wallet_balance + ? WHERE phone = ?");
                $walletStmt->execute([$wage, $employee_phone]);

                // Başvuruyu completed yap
                $updateApp = $conn->prepare("UPDATE job_applications SET status = 'completed' WHERE id = ?");
                $updateApp->execute([$application_id]);
                
                // İlanı kapalı yap
                $updateJob = $conn->prepare("UPDATE jobs SET status = 'closed' WHERE id = ?");
                $updateJob->execute([$job_id]);

                echo json_encode(["status" => "success", "message" => "İş tamamlandı ve bakiye aktarıldı."]);
            } else {
                echo json_encode(["status" => "error", "message" => "İlan bulunamadı."]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Başvuru bulunamadı."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Geçersiz işlem."]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İşlem sırasında hata oluştu: " . $e->getMessage()]);
}
?>
