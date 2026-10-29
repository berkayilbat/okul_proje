<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Eski backend/seed.php'deki demo verisi (şifre: 123456).
     */
    public function run(): void
    {
        $password = Hash::make('123456');

        DB::table('users')->insert([
            [
                'id' => 1, 'role' => 'Employer', 'first_name' => 'Berkay', 'last_name' => 'Yılbat',
                'phone' => '05445073525', 'password' => $password, 'tc_kimlik_no' => '',
                'company_name' => 'Gig Jet Organizasyon', 'tax_no' => '12067217062', 'profile_image' => null,
                'wallet_balance' => 15000.00, 'average_rating' => 4.90, 'birth_date' => '1995-05-15',
                'address' => 'Çankaya, Ankara', 'professions' => null, 'certificates_json' => null,
                'past_workplaces_json' => null, 'is_profile_complete' => 1,
            ],
            [
                'id' => 2, 'role' => 'Employee', 'first_name' => 'Berat', 'last_name' => 'Taştekin',
                'phone' => '05438296484', 'password' => $password, 'tc_kimlik_no' => '12463228334',
                'company_name' => '', 'tax_no' => null, 'profile_image' => null,
                'wallet_balance' => 3500.00, 'average_rating' => 4.85, 'birth_date' => '2000-04-02',
                'address' => 'Mamak, Ankara', 'professions' => 'Garson, Barmen, Karşılama Görevlisi',
                'certificates_json' => '[]', 'past_workplaces_json' => '[]', 'is_profile_complete' => 1,
            ],
            [
                'id' => 3, 'role' => 'Employee', 'first_name' => 'Caner', 'last_name' => 'Yıldız',
                'phone' => '05551112233', 'password' => $password, 'tc_kimlik_no' => '98765432101',
                'company_name' => '', 'tax_no' => null, 'profile_image' => null,
                'wallet_balance' => 1200.00, 'average_rating' => 4.70, 'birth_date' => '1998-09-20',
                'address' => 'Yenimahalle, Ankara', 'professions' => 'Vale, Aşçı Yardımcısı, Kurye',
                'certificates_json' => '[]', 'past_workplaces_json' => '[]', 'is_profile_complete' => 1,
            ],
        ]);

        $employer = '05445073525';
        DB::table('jobs')->insert([
            [
                'id' => 1, 'employer_phone' => $employer, 'title' => 'Konser Organizasyonu Garson',
                'location' => 'Çankaya / Tunalı Hilmi', 'working_hours' => '17:00 - 23:00', 'wage' => 850.00,
                'description' => 'Büyük canlı müzik konserimizde VIP ve loca alanlarında servis yapacak, diksiyonu düzgün ve dinamik garsonlar aranmaktadır. Servis ve yemek dahildir.',
                'dates' => '18 Ekim 2026', 'worker_count' => 3, 'status' => 'open',
            ],
            [
                'id' => 2, 'employer_phone' => $employer, 'title' => 'Özel Davet Vale Görevlisi',
                'location' => 'Yenimahalle / Batıkent', 'working_hours' => '18:00 - 01:00', 'wage' => 1200.00,
                'description' => 'Düğün ve özel balo organizasyonumuzda misafir araçlarının güvenli karşılanması, yönlendirilmesi ve park hizmeti verilmesi için B sınıfı ehliyetli çalışma arkadaşı aranıyor.',
                'dates' => '19 Ekim 2026', 'worker_count' => 2, 'status' => 'open',
            ],
            [
                'id' => 3, 'employer_phone' => $employer, 'title' => 'Fuar Tanıtım & Stand Hostu',
                'location' => 'Altındağ / ATO Congresium', 'working_hours' => '10:00 - 18:00', 'wage' => 950.00,
                'description' => 'Uluslararası bilişim ve girişimcilik fuarında şirket standımızda ziyaretçilere broşür dağıtımı, karşılama ve kayıt desteği sunacak ekip arkadaşı.',
                'dates' => '20 Ekim 2026', 'worker_count' => 4, 'status' => 'open',
            ],
            [
                'id' => 4, 'employer_phone' => $employer, 'title' => 'Cafe & Bistro Barista / Servis',
                'location' => 'Kızılay / Meşrutiyet Cad.', 'working_hours' => '12:00 - 20:00', 'wage' => 750.00,
                'description' => 'Yoğun öğle ve akşam saatlerinde sıcak/soğuk içecek servisi ve masa düzeninden sorumlu olacak tecrübeli veya öğrenmeye açık personel.',
                'dates' => '21 Ekim 2026', 'worker_count' => 1, 'status' => 'open',
            ],
            [
                'id' => 5, 'employer_phone' => $employer, 'title' => 'Hafta Sonu Etkinlik Destek Personeli',
                'location' => 'Gölbaşı / Mogan Park', 'working_hours' => '09:00 - 17:00', 'wage' => 1100.00,
                'description' => 'Açık hava kurumsal piknik organizasyonunda lojistik taşıma, masa yerleşimi ve katılımcı yönlendirmesi desteği.',
                'dates' => '12 Ekim 2026', 'worker_count' => 2, 'status' => 'closed',
            ],
        ]);

        DB::table('job_applications')->insert([
            [
                'id' => 1, 'job_id' => 1, 'employee_phone' => '05438296484', 'status' => 'applied',
                'rating' => null, 'review_comment' => null, 'employer_rating' => null, 'employer_review_comment' => null,
            ],
            [
                'id' => 2, 'job_id' => 5, 'employee_phone' => '05438296484', 'status' => 'completed',
                'rating' => 5, 'review_comment' => 'İşini zamanında ve büyük bir özveriyle yaptı. Çok memnun kaldık, teşekkürler.',
                'employer_rating' => 5, 'employer_review_comment' => 'Organizasyon son derece profesyoneldi, ödeme anında hesabıma geçti. Harika bir işveren.',
            ],
        ]);
    }
}
