<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 60 istek / 60 saniye
apply_rate_limit($conn, 'get_jobs', 60, 60, 30);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
$action = sanitize_enum($data->action ?? null, ['employer_jobs', 'all'], 'all');

try {
    $baseQuery = "
        SELECT j.*,
               COALESCE(app_stats.accepted_count, 0) AS accepted_count,
               COALESCE(app_stats.applied_count, 0) AS applied_count
        FROM jobs j
        LEFT JOIN (
            SELECT job_id,
                   COUNT(*) AS applied_count,
                   SUM(CASE WHEN status IN ('accepted', 'in_progress', 'completed') THEN 1 ELSE 0 END) AS accepted_count
            FROM job_applications
            GROUP BY job_id
        ) app_stats ON j.id = app_stats.job_id
    ";

    if ($action === 'employer_jobs') {
        // İşverenin kendi açtığı ilanları getirir
        $employer_phone = sanitize_phone($data->employer_phone ?? '');
        $stmt = $conn->prepare($baseQuery . " WHERE j.employer_phone = ? ORDER BY j.id DESC");
        $stmt->execute([$employer_phone]);
        $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "data" => $jobs]);
    } else {
        // Tüm açık ilanları (Çalışan tarafı için)
        $stmt = $conn->query($baseQuery . " WHERE j.status = 'open' ORDER BY j.id DESC");
        $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "data" => $jobs]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İlanlar çekilirken hata oluştu: " . $e->getMessage()]);
}
?>