<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
$action = isset($data->action) ? $data->action : '';

try {
    if ($action === 'employee_apps') {
        // Çalışanın başvurduğu ilanları ve başvuru durumlarını getir
        $employee_phone = $data->employee_phone;
        $stmt = $conn->prepare("
            SELECT ja.id as application_id, ja.job_id, ja.status as app_status, j.* 
            FROM job_applications ja 
            JOIN jobs j ON ja.job_id = j.id 
            WHERE ja.employee_phone = ? 
            ORDER BY ja.id DESC
        ");
        $stmt->execute([$employee_phone]);
        $apps = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "data" => $apps]);
    } else if ($action === 'employer_apps') {
        // İşverenin açtığı ilanlara gelen tüm başvurular ve başvuran kişilerin isimleri
        $employer_phone = $data->employer_phone;
        $stmt = $conn->prepare("
            SELECT ja.id as application_id, ja.job_id, ja.status as app_status, j.title, u.first_name, u.last_name, u.phone as employee_phone
            FROM job_applications ja
            JOIN jobs j ON ja.job_id = j.id
            JOIN users u ON ja.employee_phone = u.phone
            WHERE j.employer_phone = ?
            ORDER BY ja.id DESC
        ");
        $stmt->execute([$employer_phone]);
        $apps = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "data" => $apps]);
    } else {
        echo json_encode(["status" => "error", "message" => "Geçersiz action."]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Başvurular çekilirken hata oluştu: " . $e->getMessage()]);
}
?>
