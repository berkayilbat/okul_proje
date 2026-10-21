<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->application_id) || !isset($data->action)) {
    echo json_encode(["status" => "error", "message" => "Eksik parametre gönderildi."]);
    exit();
}

$application_id = sanitize_int($data->application_id, 0, 1);
$action = sanitize_enum($data->action, ['accept', 'reject', 'start_work', 'complete'], null);

if ($application_id <= 0 || $action === null) {
    echo json_encode(["status" => "error", "message" => "Geçersiz başvuru veya işlem türü."]);
    exit();
}

try {
    if ($action === 'accept') {
        // Başvuru ve ilanın kontenjan durumunu doğrula
        $appStmt = $conn->prepare("SELECT job_id, status FROM job_applications WHERE id = ?");
        $appStmt->execute([$application_id]);
        $app = $appStmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            echo json_encode(["status" => "error", "message" => "Başvuru bulunamadı."]);
            exit();
        }

        $job_id = (int)$app['job_id'];

        $jobStmt = $conn->prepare("SELECT worker_count, status FROM jobs WHERE id = ?");
        $jobStmt->execute([$job_id]);
        $job = $jobStmt->fetch(PDO::FETCH_ASSOC);

        if (!$job) {
            echo json_encode(["status" => "error", "message" => "İlan bulunamadı."]);
            exit();
        }

        $workerCount = (int)($job['worker_count'] ?? 1);

        $countStmt = $conn->prepare("SELECT COUNT(*) FROM job_applications WHERE job_id = ? AND status IN ('accepted', 'in_progress', 'completed')");
        $countStmt->execute([$job_id]);
        $filledCount = (int)$countStmt->fetchColumn();

        if ($filledCount >= $workerCount) {
            echo json_encode([
                "status" => "error",
                "message" => "Bu ilan için belirlenen kontenjan dolmuştur ($workerCount/$workerCount kişi)."
            ]);
            exit();
        }

        $stmt = $conn->prepare("UPDATE job_applications SET status = 'accepted' WHERE id = ?");
        $stmt->execute([$application_id]);
        echo json_encode(["status" => "success", "message" => "Başvuru onaylandı."]);

    } else if ($action === 'reject') {
        $stmt = $conn->prepare("UPDATE job_applications SET status = 'rejected' WHERE id = ?");
        $stmt->execute([$application_id]);
        echo json_encode(["status" => "success", "message" => "Başvuru reddedildi."]);

    } else if ($action === 'start_work') {
        $stmt = $conn->prepare("UPDATE job_applications SET status = 'in_progress' WHERE id = ?");
        $stmt->execute([$application_id]);
        echo json_encode(["status" => "success", "message" => "Çalışma Başarıyla Başlatıldı!"]);

    } else if ($action === 'complete') {
        // İşi bitirme ve cüzdan transfer işlemi
        $appStmt = $conn->prepare("SELECT job_id, employee_phone, status FROM job_applications WHERE id = ?");
        $appStmt->execute([$application_id]);
        $application = $appStmt->fetch(PDO::FETCH_ASSOC);

        if (!$application) {
            echo json_encode(["status" => "error", "message" => "Başvuru bulunamadı."]);
            exit();
        }

        if ($application['status'] === 'completed') {
            echo json_encode(["status" => "success", "message" => "İş zaten tamamlanmış."]);
            exit();
        }

        $job_id = (int)$application['job_id'];
        $employee_phone = $application['employee_phone'];

        // İlandan ücreti, işveren telefonunu ve worker_count bilgisini al
        $jobStmt = $conn->prepare("SELECT wage, employer_phone, worker_count FROM jobs WHERE id = ?");
        $jobStmt->execute([$job_id]);
        $job = $jobStmt->fetch(PDO::FETCH_ASSOC);

        if ($job) {
            $wage = floatval($job['wage']);
            $employer_phone = $job['employer_phone'];
            $workerCount = (int)($job['worker_count'] ?? 1);

            $conn->beginTransaction();

            try {
                // Çalışanın cüzdanına ekle
                $walletStmt = $conn->prepare("UPDATE users SET wallet_balance = wallet_balance + ? WHERE phone = ?");
                $walletStmt->execute([$wage, $employee_phone]);

                // İşverenin cüzdanından düş (canlı para transferi)
                if (!empty($employer_phone)) {
                    $empWalletStmt = $conn->prepare("UPDATE users SET wallet_balance = wallet_balance - ? WHERE phone = ?");
                    $empWalletStmt->execute([$wage, $employer_phone]);
                }

                // Başvuruyu completed yap
                $updateApp = $conn->prepare("UPDATE job_applications SET status = 'completed' WHERE id = ?");
                $updateApp->execute([$application_id]);
                
                // Çoklu çalışan kontrolü: Eğer hala aktif ('accepted' veya 'in_progress') çalışan kalmadıysa
                // ve tamamlanan çalışan sayısı kontenjana ulaştıysa ilanı kapat ('closed')
                $activeCountStmt = $conn->prepare("SELECT COUNT(*) FROM job_applications WHERE job_id = ? AND status IN ('accepted', 'in_progress')");
                $activeCountStmt->execute([$job_id]);
                $remainingActive = (int)$activeCountStmt->fetchColumn();

                $completedCountStmt = $conn->prepare("SELECT COUNT(*) FROM job_applications WHERE job_id = ? AND status = 'completed'");
                $completedCountStmt->execute([$job_id]);
                $completedCount = (int)$completedCountStmt->fetchColumn();

                if ($remainingActive === 0 && $completedCount >= $workerCount) {
                    $updateJob = $conn->prepare("UPDATE jobs SET status = 'closed' WHERE id = ?");
                    $updateJob->execute([$job_id]);
                }

                $conn->commit();

                echo json_encode([
                    "status" => "success", 
                    "message" => "İş tamamlandı! $wage TL ücret hesaba aktarıldı."
                ]);
            } catch (Exception $txEx) {
                $conn->rollBack();
                throw $txEx;
            }
        } else {
            echo json_encode(["status" => "error", "message" => "İlan bulunamadı."]);
        }
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İşlem gerçekleştirilemedi: " . $e->getMessage()]);
}
?>