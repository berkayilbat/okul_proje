<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

$action = isset($data->action) ? $data->action : 'all';

try {
    if ($action === 'employer_jobs') {
        // İşverenin kendi açtığı ilanları getirir
        $employer_phone = $data->employer_phone;
        $stmt = $conn->prepare("SELECT * FROM jobs WHERE employer_phone = ? ORDER BY id DESC");
        $stmt->execute([$employer_phone]);
        $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "data" => $jobs]);
    } else {
        // Tüm açık ilanları (Çalışan tarafı için)
        $stmt = $conn->query("SELECT * FROM jobs WHERE status = 'open' ORDER BY id DESC");
        $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "data" => $jobs]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "İlanlar çekilirken hata oluştu: " . $e->getMessage()]);
}
?>
