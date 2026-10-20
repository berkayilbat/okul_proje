<?php
require_once 'db.php';

$phone = isset($_POST['phone']) ? sanitize_phone($_POST['phone']) : '';
$address = isset($_POST['address']) ? sanitize_text($_POST['address'], 255) : null;
$professions = isset($_POST['professions']) ? sanitize_text($_POST['professions'], 255) : null;

if (empty($phone)) {
    echo json_encode(["status" => "error", "message" => "Telefon numarası eksik veya geçersiz."]);
    exit();
}

$allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
$maxFileSize = 5 * 1024 * 1024; // 5 MB

function processUploadedFiles($fileKey, $allowedExtensions, $maxFileSize) {
    if (!isset($_FILES[$fileKey])) return [];
    
    $uploadedPaths = [];
    $uploadDir = __DIR__ . '/uploads/';
    if (!is_dir($uploadDir)) {
        @mkdir($uploadDir, 0755, true);
    }

    $files = $_FILES[$fileKey];
    $count = is_array($files['name']) ? count($files['name']) : 0;

    for ($i = 0; $i < $count; $i++) {
        if (isset($files['error'][$i]) && $files['error'][$i] === UPLOAD_ERR_OK) {
            $tmpName = $files['tmp_name'][$i];
            $size = $files['size'][$i];
            $ext = strtolower(pathinfo($files['name'][$i], PATHINFO_EXTENSION));

            if ($size > $maxFileSize) {
                continue;
            }

            if (!in_array($ext, $allowedExtensions)) {
                continue;
            }

            $newFileName = bin2hex(random_bytes(16)) . '.' . $ext;
            $destination = $uploadDir . $newFileName;
            if (@move_uploaded_file($tmpName, $destination)) {
                $uploadedPaths[] = 'uploads/' . $newFileName;
            }
        }
    }
    return $uploadedPaths;
}

try {
    processUploadedFiles('certificates', $allowedExtensions, $maxFileSize);
    processUploadedFiles('past_workplaces', $allowedExtensions, $maxFileSize);

    $stmt = $conn->prepare("UPDATE users SET address = ?, professions = ?, is_profile_complete = 1 WHERE phone = ?");
    $stmt->execute([$address, $professions, $phone]);

    echo json_encode(["status" => "success", "message" => "Çalışan profili tamamlandı."]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Profil güncellenirken bir hata oluştu: " . $e->getMessage()]);
}
?>