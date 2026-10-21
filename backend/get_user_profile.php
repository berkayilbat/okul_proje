<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->phone)) {
    echo json_encode(["status" => "error", "message" => "Telefon numarası gerekli."]);
    exit();
}

$phone = sanitize_phone($data->phone);
$role = sanitize_enum($data->role ?? null, ['Employer', 'Employee'], 'Employee');

if (empty($phone)) {
    echo json_encode(["status" => "error", "message" => "Geçerli bir telefon numarası girin."]);
    exit();
}

try {
    $stmt = $conn->prepare("SELECT wallet_balance, average_rating, first_name, last_name, company_name, profile_image FROM users WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    $wallet_balance = $user ? floatval($user['wallet_balance'] ?? 0.0) : 0.0;
    $average_rating = $user ? floatval($user['average_rating'] ?? 5.0) : 5.0;
    $profile_image = $user ? ($user['profile_image'] ?? null) : null;

    $job_count = 0;
    $recent_jobs = [];
    $last_payment = "Henüz işlem yok";

    if ($role === 'Employer') {
        // İşverenin açtığı toplam ilan sayısı
        $countStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM jobs WHERE employer_phone = ?");
        $countStmt->execute([$phone]);
        $row = $countStmt->fetch(PDO::FETCH_ASSOC);
        $job_count = $row ? intval($row['cnt']) : 0;

        // Son ilanlar
        $recentStmt = $conn->prepare("
            SELECT j.title, j.location as subtitle, COALESCE(ja.employer_rating, 5.0) as rating, j.wage, j.status
            FROM jobs j
            LEFT JOIN job_applications ja ON j.id = ja.job_id AND ja.status = 'completed'
            WHERE j.employer_phone = ? 
            ORDER BY j.id DESC LIMIT 5
        ");
        $recentStmt->execute([$phone]);
        $recent_jobs = $recentStmt->fetchAll(PDO::FETCH_ASSOC);

        // Son yapılan ödeme
        $payStmt = $conn->prepare("
            SELECT j.wage, j.title
            FROM job_applications ja
            JOIN jobs j ON ja.job_id = j.id
            WHERE j.employer_phone = ? AND ja.status = 'completed'
            ORDER BY ja.updated_at DESC LIMIT 1
        ");
        $payStmt->execute([$phone]);
        $lastPay = $payStmt->fetch(PDO::FETCH_ASSOC);
        if ($lastPay) {
            $last_payment = "-" . floatval($lastPay['wage']) . " TL (" . $lastPay['title'] . ")";
        }

    } else {
        // Çalışanın tamamladığı iş sayısı
        $countStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM job_applications WHERE employee_phone = ? AND status = 'completed'");
        $countStmt->execute([$phone]);
        $row = $countStmt->fetch(PDO::FETCH_ASSOC);
        $job_count = $row ? intval($row['cnt']) : 0;

        // Son tamamlanan işler
        $recentStmt = $conn->prepare("
            SELECT j.title, j.location as subtitle, COALESCE(ja.rating, 5.0) as rating, j.wage
            FROM job_applications ja 
            JOIN jobs j ON ja.job_id = j.id 
            WHERE ja.employee_phone = ? AND ja.status = 'completed' 
            ORDER BY ja.id DESC LIMIT 5
        ");
        $recentStmt->execute([$phone]);
        $recent_jobs = $recentStmt->fetchAll(PDO::FETCH_ASSOC);

        // Son alınan ödeme
        $payStmt = $conn->prepare("
            SELECT j.wage, j.title
            FROM job_applications ja
            JOIN jobs j ON ja.job_id = j.id
            WHERE ja.employee_phone = ? AND ja.status = 'completed'
            ORDER BY ja.updated_at DESC LIMIT 1
        ");
        $payStmt->execute([$phone]);
        $lastPay = $payStmt->fetch(PDO::FETCH_ASSOC);
        if ($lastPay) {
            $last_payment = "+" . floatval($lastPay['wage']) . " TL (" . $lastPay['title'] . ")";
        }
    }

    echo json_encode([
        "status" => "success",
        "data" => [
            "wallet_balance" => $wallet_balance,
            "job_count" => $job_count,
            "average_rating" => $average_rating,
            "last_payment" => $last_payment,
            "recent_jobs" => $recent_jobs,
            "profile_image" => $profile_image
        ]
    ]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Hata: " . $e->getMessage()]);
}
?>