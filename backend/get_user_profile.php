<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->phone)) {
    echo json_encode(["status" => "error", "message" => "Telefon numarası gerekli."]);
    exit();
}

$phone = $data->phone;
$role = isset($data->role) ? $data->role : 'Employee';

try {
    $stmt = $conn->prepare("SELECT wallet_balance, average_rating FROM users WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    $wallet_balance = $user ? floatval($user['wallet_balance'] ?? 0.0) : 0.0;
    $average_rating = $user ? floatval($user['average_rating'] ?? 5.0) : 5.0;

    $job_count = 0;
    $recent_jobs = [];

    if ($role === 'Employer') {
        $countStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM jobs WHERE employer_phone = ?");
        $countStmt->execute([$phone]);
        $row = $countStmt->fetch(PDO::FETCH_ASSOC);
        $job_count = $row ? intval($row['cnt']) : 0;

        $recentStmt = $conn->prepare("SELECT title, location as subtitle, 5.0 as rating FROM jobs WHERE employer_phone = ? ORDER BY id DESC LIMIT 5");
        $recentStmt->execute([$phone]);
        $recent_jobs = $recentStmt->fetchAll(PDO::FETCH_ASSOC);
    } else {
        $countStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM job_applications WHERE employee_phone = ? AND status = 'completed'");
        $countStmt->execute([$phone]);
        $row = $countStmt->fetch(PDO::FETCH_ASSOC);
        $job_count = $row ? intval($row['cnt']) : 0;

        $recentStmt = $conn->prepare("
            SELECT j.title, j.location as subtitle, 5.0 as rating 
            FROM job_applications ja 
            JOIN jobs j ON ja.job_id = j.id 
            WHERE ja.employee_phone = ? AND ja.status = 'completed' 
            ORDER BY ja.id DESC LIMIT 5
        ");
        $recentStmt->execute([$phone]);
        $recent_jobs = $recentStmt->fetchAll(PDO::FETCH_ASSOC);
    }

    echo json_encode([
        "status" => "success",
        "data" => [
            "wallet_balance" => $wallet_balance,
            "job_count" => $job_count,
            "average_rating" => $average_rating,
            "recent_jobs" => $recent_jobs
        ]
    ]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Hata: " . $e->getMessage()]);
}
?>
