<?php
require_once 'db.php';

header("Content-Type: application/json; charset=UTF-8");

$action = isset($_GET['action']) ? $_GET['action'] : 'clear';

try {
    $conn->exec("SET FOREIGN_KEY_CHECKS = 0;");

    if ($action === 'drop') {
        // Tabloları tamamen siler
        $conn->exec("DROP TABLE IF EXISTS `job_applications`;");
        $conn->exec("DROP TABLE IF EXISTS `jobs`;");
        $conn->exec("DROP TABLE IF EXISTS `users`;");
        $conn->exec("SET FOREIGN_KEY_CHECKS = 1;");
        echo json_encode([
            "status" => "success",
            "action" => "drop",
            "message" => "Tüm tablolar başarıyla silindi (Veritabanı tamamen sıfırlandı)."
        ]);
        exit();
    }

    if ($action === 'clear') {
        // Tablolar durur, içindeki tüm veriler (test ilanları, başvurular, kullanıcılar) temizlenir
        $conn->exec("TRUNCATE TABLE `job_applications`;");
        $conn->exec("TRUNCATE TABLE `jobs`;");
        $conn->exec("TRUNCATE TABLE `users`;");
        $conn->exec("SET FOREIGN_KEY_CHECKS = 1;");
        echo json_encode([
            "status" => "success",
            "action" => "clear",
            "message" => "Tüm test verileri temizlendi. Tablolar artık bomboş."
        ]);
        exit();
    }

    if ($action === 'seed') {
        // seed.php'yi çalıştırıp fabrika demo ayarlarına döndürür
        $conn->exec("SET FOREIGN_KEY_CHECKS = 1;");
        require_once 'seed.php';
        exit();
    }

    $conn->exec("SET FOREIGN_KEY_CHECKS = 1;");
    echo json_encode([
        "status" => "error",
        "message" => "Geçersiz işlem. Kullanılabilir eylemler: ?action=clear (verileri sil), ?action=drop (tabloları yok et), ?action=seed (demo verilerini yükle)"
    ]);
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => "İşlem sırasında hata oluştu: " . $e->getMessage()
    ]);
}
?>
