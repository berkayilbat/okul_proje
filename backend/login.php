<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Invalid request method."]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->phone) || !isset($data->password) || !isset($data->role)) {
    echo json_encode(["status" => "error", "message" => "Eksik giriş bilgileri."]);
    exit();
}

$phone = $data->phone;
$password = $data->password;
$role = $data->role;

$stmt = $conn->prepare("SELECT * FROM users WHERE phone = ? LIMIT 1");
$stmt->execute([$phone]);

if ($stmt->rowCount() > 0) {
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Şifre kontrolü
    if ($password === $user['password']) {
        // Rol kontrolü (Eğer seçilen sekme kayıtlı rol ile eşleşmiyorsa)
        if ($role === $user['role']) {
            // Şifreyi güvenlik gereği çıkarıyoruz (Eğer isterseniz jwt de verilebilir)
            unset($user['password']);
            echo json_encode(["status" => "success", "message" => "Giriş başarılı.", "user" => $user]);
        } else {
            echo json_encode(["status" => "error", "message" => "Hesabınızın türü (İşveren/Çalışan) yanlış seçilmiş."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Şifre hatalı."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Kullanıcı bulunamadı."]);
}
?>
