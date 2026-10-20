<?php
require_once 'db.php';

header("Content-Type: application/json; charset=UTF-8");

try {
    // 1. users tablosunu oluştur
    $conn->exec("
        CREATE TABLE IF NOT EXISTS `users` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `role` varchar(50) NOT NULL COMMENT 'Employee veya Employer',
          `first_name` varchar(100) NOT NULL,
          `last_name` varchar(100) NOT NULL,
          `phone` varchar(20) NOT NULL UNIQUE,
          `password` varchar(255) NOT NULL,
          `tc_kimlik_no` varchar(11) DEFAULT NULL,
          `company_name` varchar(255) DEFAULT NULL,
          `tax_no` varchar(20) DEFAULT NULL,
          `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `wallet_balance` decimal(10,2) NOT NULL DEFAULT 0.00,
          `average_rating` decimal(3,2) NOT NULL DEFAULT 5.00,
          `birth_date` date DEFAULT NULL,
          `address` text DEFAULT NULL,
          `professions` text DEFAULT NULL,
          `certificates_json` text DEFAULT NULL,
          `past_workplaces_json` text DEFAULT NULL,
          `is_profile_complete` tinyint(1) DEFAULT 0,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    // Eksik sütun kontrolü (eğer users tablosu önceden varsa)
    $columns = $conn->query("SHOW COLUMNS FROM users")->fetchAll(PDO::FETCH_COLUMN);
    if (!in_array('average_rating', $columns)) {
        $conn->exec("ALTER TABLE users ADD COLUMN `average_rating` decimal(3,2) NOT NULL DEFAULT 5.00 AFTER `wallet_balance`");
    }
    if (!in_array('wallet_balance', $columns)) {
        $conn->exec("ALTER TABLE users ADD COLUMN `wallet_balance` decimal(10,2) NOT NULL DEFAULT 0.00 AFTER `created_at`");
    }

    // 2. jobs tablosunu oluştur
    $conn->exec("
        CREATE TABLE IF NOT EXISTS `jobs` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `employer_phone` varchar(20) NOT NULL,
          `title` varchar(255) NOT NULL,
          `location` varchar(255) NOT NULL,
          `working_hours` varchar(100) NOT NULL,
          `wage` decimal(10,2) NOT NULL,
          `description` text NOT NULL,
          `dates` varchar(100) NOT NULL,
          `status` varchar(50) NOT NULL DEFAULT 'open',
          `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    // 3. job_applications tablosunu oluştur
    $conn->exec("
        CREATE TABLE IF NOT EXISTS `job_applications` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `job_id` int(11) NOT NULL,
          `employee_phone` varchar(20) NOT NULL,
          `status` varchar(50) NOT NULL DEFAULT 'applied',
          `rating` int(11) DEFAULT NULL,
          `review_comment` text DEFAULT NULL,
          `employer_rating` int(11) DEFAULT NULL,
          `employer_review_comment` text DEFAULT NULL,
          `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `job_id` (`job_id`),
          KEY `employee_phone` (`employee_phone`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    // Eksik sütun kontrolü (job_applications için)
    $appCols = $conn->query("SHOW COLUMNS FROM job_applications")->fetchAll(PDO::FETCH_COLUMN);
    if (!in_array('rating', $appCols)) {
        $conn->exec("ALTER TABLE job_applications ADD COLUMN `rating` int(11) DEFAULT NULL");
    }
    if (!in_array('review_comment', $appCols)) {
        $conn->exec("ALTER TABLE job_applications ADD COLUMN `review_comment` text DEFAULT NULL");
    }
    if (!in_array('employer_rating', $appCols)) {
        $conn->exec("ALTER TABLE job_applications ADD COLUMN `employer_rating` int(11) DEFAULT NULL");
    }
    if (!in_array('employer_review_comment', $appCols)) {
        $conn->exec("ALTER TABLE job_applications ADD COLUMN `employer_review_comment` text DEFAULT NULL");
    }

    // Tabloları temizle ve hazır demo verisi ile doldur
    $conn->exec("SET FOREIGN_KEY_CHECKS = 0;");
    $conn->exec("TRUNCATE TABLE job_applications;");
    $conn->exec("TRUNCATE TABLE jobs;");
    $conn->exec("TRUNCATE TABLE users;");
    $conn->exec("SET FOREIGN_KEY_CHECKS = 1;");

    // 4. DEMO KULLANICILARINI EKLE
    // Şifreler: '123456' ve geriye dönük 'berkay123.' için Bcrypt hash
    $hashedPassword = password_hash('123456', PASSWORD_BCRYPT);

    $userStmt = $conn->prepare("
        INSERT INTO users (
            id, role, first_name, last_name, phone, password, 
            tc_kimlik_no, company_name, tax_no, wallet_balance, average_rating, 
            birth_date, address, professions, certificates_json, past_workplaces_json, is_profile_complete
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    // İşveren (Berkay / Gig Jet Organizasyon)
    $userStmt->execute([
        1, 'Employer', 'Berkay', 'Yılbat', '05445073525', $hashedPassword,
        '', 'Gig Jet Organizasyon', '12067217062', 15000.00, 4.90,
        '1995-05-15', 'Çankaya, Ankara', NULL, NULL, NULL, 1
    ]);

    // Çalışan (Berat Taştekin)
    $userStmt->execute([
        2, 'Employee', 'Berat', 'Taştekin', '05438296484', $hashedPassword,
        '12463228334', '', NULL, 3500.00, 4.85,
        '2000-04-02', 'Mamak, Ankara', 'Garson, Barmen, Karşılama Görevlisi', '[]', '[]', 1
    ]);

    // İkinci Çalışan (Caner Yıldız)
    $userStmt->execute([
        3, 'Employee', 'Caner', 'Yıldız', '05551112233', $hashedPassword,
        '98765432101', '', NULL, 1200.00, 4.70,
        '1998-09-20', 'Yenimahalle, Ankara', 'Vale, Aşçı Yardımcısı, Kurye', '[]', '[]', 1
    ]);

    // 5. DEMO İLANLARINI EKLE
    $jobStmt = $conn->prepare("
        INSERT INTO jobs (id, employer_phone, title, location, working_hours, wage, description, dates, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $jobsData = [
        [
            1, '05445073525', 'Konser Organizasyonu Garson', 'Çankaya / Tunalı Hilmi', '17:00 - 23:00', 850.00,
            'Büyük canlı müzik konserimizde VIP ve loca alanlarında servis yapacak, diksiyonu düzgün ve dinamik garsonlar aranmaktadır. Servis ve yemek dahildir.',
            '18 Ekim 2026', 'open'
        ],
        [
            2, '05445073525', 'Özel Davet Vale Görevlisi', 'Yenimahalle / Batıkent', '18:00 - 01:00', 1200.00,
            'Düğün ve özel balo organizasyonumuzda misafir araçlarının güvenli karşılanması, yönlendirilmesi ve park hizmeti verilmesi için B sınıfı ehliyetli çalışma arkadaşı aranıyor.',
            '19 Ekim 2026', 'open'
        ],
        [
            3, '05445073525', 'Fuar Tanıtım & Stand Hostu', 'Altındağ / ATO Congresium', '10:00 - 18:00', 950.00,
            'Uluslararası bilişim ve girişimcilik fuarında şirket standımızda ziyaretçilere broşür dağıtımı, karşılama ve kayıt desteği sunacak ekip arkadaşı.',
            '20 Ekim 2026', 'open'
        ],
        [
            4, '05445073525', 'Cafe & Bistro Barista / Servis', 'Kızılay / Meşrutiyet Cad.', '12:00 - 20:00', 750.00,
            'Yoğun öğle ve akşam saatlerinde sıcak/soğuk içecek servisi ve masa düzeninden sorumlu olacak tecrübeli veya öğrenmeye açık personel.',
            '21 Ekim 2026', 'open'
        ],
        [
            5, '05445073525', 'Hafta Sonu Etkinlik Destek Personeli', 'Gölbaşı / Mogan Park', '09:00 - 17:00', 1100.00,
            'Açık hava kurumsal piknik organizasyonunda lojistik taşıma, masa yerleşimi ve katılımcı yönlendirmesi desteği.',
            '12 Ekim 2026', 'closed' // Geçmiş tamamlanmış iş örneği
        ]
    ];

    foreach ($jobsData as $j) {
        $jobStmt->execute($j);
    }

    // 6. DEMO BAŞVURULARI EKLE
    $appStmt = $conn->prepare("
        INSERT INTO job_applications (id, job_id, employee_phone, status, rating, review_comment, employer_rating, employer_review_comment)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");

    // İlan 1 (Konser Garson) -> Berat başvurmuş (applied): İşveren bunu direkt 'Onayla' yapıp demo başlatabilir!
    $appStmt->execute([
        1, 1, '05438296484', 'applied', NULL, NULL, NULL, NULL
    ]);

    // İlan 5 (Geçmiş İş) -> Berat tamamlamış (completed): Karşılıklı değerlendirilmiş ve yorum yapılmış
    $appStmt->execute([
        2, 5, '05438296484', 'completed', 5, 'İşini zamanında ve büyük bir özveriyle yaptı. Çok memnun kaldık, teşekkürler.', 5, 'Organizasyon son derece profesyoneldi, ödeme anında hesabıma geçti. Harika bir işveren.'
    ]);

    echo json_encode([
        "status" => "success",
        "message" => "Örnek veriler ve tablolar başarıyla yüklendi! Demo hazır.",
        "data" => [
            "employer" => ["phone" => "05445073525", "password" => "123456", "role" => "Employer", "name" => "Berkay Yılbat"],
            "employee" => ["phone" => "05438296484", "password" => "123456", "role" => "Employee", "name" => "Berat Taştekin"],
            "jobs_count" => 5,
            "applications_count" => 2
        ]
    ]);

} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Seed verileri yüklenirken hata oluştu: " . $e->getMessage()
    ]);
}
?>
