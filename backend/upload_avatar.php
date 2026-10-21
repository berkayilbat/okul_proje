<?php
require_once 'db.php';

// IP Bazlı Hız Sınırı: 15 istek / 60 saniye
apply_rate_limit($conn, 'upload_avatar', 15, 60, 60);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Geçersiz istek metodu."]);
    exit();
}

$rawInput = file_get_contents("php://input");
$jsonData = json_decode($rawInput, true);

$phone = '';
if (isset($_POST['phone'])) {
    $phone = sanitize_phone($_POST['phone']);
} elseif (is_array($jsonData) && isset($jsonData['phone'])) {
    $phone = sanitize_phone($jsonData['phone']);
}

if (empty($phone)) {
    echo json_encode(["status" => "error", "message" => "Telefon numarası eksik veya geçersiz."]);
    exit();
}

// Kullanıcı kontrolü
$stmt = $conn->prepare("SELECT id, profile_image FROM users WHERE phone = ?");
$stmt->execute([$phone]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    echo json_encode(["status" => "error", "message" => "Kullanıcı bulunamadı."]);
    exit();
}

$action = $_POST['action'] ?? ($jsonData['action'] ?? 'upload');

// Profil fotoğrafını kaldırma
if ($action === 'delete') {
    $currentImage = $user['profile_image'];
    if (!empty($currentImage)) {
        $filePath = __DIR__ . '/' . ltrim($currentImage, '/');
        $realUploads = realpath(__DIR__ . '/uploads/avatars');
        $realFilePath = realpath($filePath);
        if ($realUploads && $realFilePath && strpos($realFilePath, $realUploads) === 0 && file_exists($realFilePath)) {
            @unlink($realFilePath);
        }
    }

    $upd = $conn->prepare("UPDATE users SET profile_image = NULL WHERE phone = ?");
    $upd->execute([$phone]);

    echo json_encode([
        "status" => "success",
        "message" => "Profil fotoğrafı başarıyla kaldırıldı.",
        "profile_image" => null
    ]);
    exit();
}

// Dosya yükleme kontrolü
if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode([
        "status" => "error",
        "message" => "Yüklenecek profil fotoğrafı bulunamadı veya yükleme hatası oluştu."
    ]);
    exit();
}

$file = $_FILES['avatar'];
$maxFileSize = 5 * 1024 * 1024; // 5 MB

if ($file['size'] > $maxFileSize) {
    echo json_encode(["status" => "error", "message" => "Fotoğraf boyutu 5 MB'tan büyük olamaz."]);
    exit();
}

$allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

if (!in_array($ext, $allowedExtensions, true)) {
    echo json_encode(["status" => "error", "message" => "Geçersiz dosya formatı. Yalnızca JPG, PNG veya WEBP formatları desteklenir."]);
    exit();
}

// MIME Type kontrolü
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

$allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
if (!in_array($mimeType, $allowedMimes, true)) {
    echo json_encode(["status" => "error", "message" => "Geçersiz görsel içeriği algılandı."]);
    exit();
}

// Gerçek görsel içeriği kontrolü
$imageSize = @getimagesize($file['tmp_name']);
if ($imageSize === false) {
    echo json_encode(["status" => "error", "message" => "Dosya geçerli bir görsel değil."]);
    exit();
}

$avatarDir = __DIR__ . '/uploads/avatars/';
if (!is_dir($avatarDir)) {
    @mkdir($avatarDir, 0755, true);
}

// Eski fotoğrafı sil
if (!empty($user['profile_image'])) {
    $oldFilePath = __DIR__ . '/' . ltrim($user['profile_image'], '/');
    $realUploads = realpath($avatarDir);
    $realOldPath = realpath($oldFilePath);
    if ($realUploads && $realOldPath && strpos($realOldPath, $realUploads) === 0 && file_exists($realOldPath)) {
        @unlink($realOldPath);
    }
}

// Benzersiz dosya ismi oluştur
$newFileName = 'avatar_' . bin2hex(random_bytes(10)) . '_' . time() . '.' . $ext;
$targetPath = $avatarDir . $newFileName;

if (!@move_uploaded_file($file['tmp_name'], $targetPath)) {
    echo json_encode(["status" => "error", "message" => "Fotoğraf kaydedilirken sunucu hatası oluştu."]);
    exit();
}

$relativePath = 'uploads/avatars/' . $newFileName;
$upd = $conn->prepare("UPDATE users SET profile_image = ? WHERE phone = ?");
$upd->execute([$relativePath, $phone]);

echo json_encode([
    "status" => "success",
    "message" => "Profil fotoğrafı başarıyla yüklendi.",
    "profile_image" => $relativePath
]);
?>