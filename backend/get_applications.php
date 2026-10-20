<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 60 istek / 60 saniye
apply_rate_limit($conn, 'get_applications', 60, 60, 30);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));
$action = isset($data->action) ? $data->action : '';

try {
    if ($action === 'employee_apps') {
        // Çalışanın başvurduğu ilanları ve başvuru durumlarını getir
        $employee_phone = isset($data->employee_phone) ? $data->employee_phone : '';
        $stmt = $conn->prepare("
            SELECT 
                ja.id as application_id, 
                ja.job_id, 
                ja.status as app_status,
                ja.rating,
                ja.review_comment,
                ja.employer_rating,
                ja.employer_review_comment,
                ja.created_at as applied_at,
                j.title,
                j.location,
                j.working_hours,
                j.wage,
                j.description,
                j.dates,
                j.status as job_status,
                j.employer_phone,
                emp.first_name as employer_first_name,
                emp.last_name as employer_last_name,
                emp.company_name
            FROM job_applications ja 
            JOIN jobs j ON ja.job_id = j.id 
            LEFT JOIN users emp ON j.employer_phone = emp.phone
            WHERE ja.employee_phone = ? 
            ORDER BY ja.id DESC
        ");
        $stmt->execute([$employee_phone]);
        $apps = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "data" => $apps]);

    } else if ($action === 'employer_apps') {
        // İşverenin açtığı ilanlara gelen tüm başvurular ve başvuran kişilerin bilgileri
        $employer_phone = isset($data->employer_phone) ? $data->employer_phone : '';
        $stmt = $conn->prepare("
            SELECT 
                ja.id as application_id, 
                ja.job_id, 
                ja.status as app_status,
                ja.rating,
                ja.review_comment,
                ja.employer_rating,
                ja.employer_review_comment,
                ja.created_at as applied_at,
                j.title,
                j.location,
                j.working_hours,
                j.wage,
                j.description,
                j.dates,
                j.status as job_status,
                u.first_name, 
                u.last_name, 
                u.phone as employee_phone,
                u.average_rating as employee_average_rating
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
