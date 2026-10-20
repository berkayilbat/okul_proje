Yömyeci — Emeğin ve Güvenin Dijital Buluşma Noktası

> *"Hafta sonu kafede acil bir baristaya mı ihtiyaç var? Ya da okuldan sonra birkaç saat çalışıp harçlığını çıkarmak isteyen bir genç misin? Yömyeci, tam olarak bu iki dünyayı en samimi, en şeffaf ve en pratik yoldan bir araya getirmek için var."*

Merhaba! **Yömyeci** projesine hoş geldin.  
Burası; aradaki karmaşık süreçleri, güvensizlikleri ve kağıt-kalem hesabını bir kenara bırakıp, günlük/yevmiyeli iş arayanlar ile dinamik işletmeleri tek bir çatı altında buluşturan samimi bir topluluk uygulamasıdır.

---

## Neden Yömyeci? (Hikayemiz)

Hepimiz biliyoruz: Hizmet sektöründe işler bir anda yoğunlaşır; bazen beklenmedik bir rezervasyon patlaması olur, bazen bir ekip arkadaşımız rahatsızlanır. İşletmeci o gün kapıyı kapatamaz; canla başla çalışacak bir dosta ihtiyaç duyar.  
Öte yandan; sınavlarından fırsat buldukça çalışmak isteyen üniversiteliler, mesleki deneyimini paraya dönüştürmek isteyen ustalar ve esnek saatlerle hayatını kazanmak isteyen yevmiyeciler var.

**Yömyeci**, bu iki tarafı birbirine güvenle bağlamak için tasarlandı:
- **Kağıt-kalem yok:** Mesainin başlangıcı ve bitişi birer QR kod okutması kadar net.
- **Soru işareti yok:** Kiminle çalışacağını önceki değerlendirmelerden ve puanlardan bilirsin.
- **Sürpriz yok:** Ücret, saatler, konum ve şartlar en baştan bellidir.

---

##  Neler Sunuyoruz?

###  İşverenler İçin
- **Dakikalar İçinde İlan:** Ankara'nın istediğin ilçesinde, ihtiyacın olan pozisyon için (Garson, Barista, Komi, Kasiyer, Temizlik vb.) anında ilan ver.
- **Başvuru Yönetimi:** Başvuran adayların profillerini, geçmiş deneyimlerini ve puanlarını incele; tek dokunuşla kabul et veya geri çevir.
- **Karekodla Mesai Kontrolü:** Çalışan dükkana adım attığında **Giriş QR Kodu (START)**, işini bitirip vedalaşırken **Çıkış QR Kodu (FINISH)** okutulsun. Her şey dijital ve anlık doğrulansın.
- **Çalışanı Değerlendir:** Günün sonunda çalışanın performansına yıldız ver, samimi bir yorum bırak.

###  Çalışanlar / Yömyeciler İçin
- **Sana En Yakın İlanlar:** Konumuna ve uzmanlığına uygun işleri listele, ilçelere göre filtrele.
- **Tek Tıkla Başvuru:** İlgilendiğin işe anında başvur, kabul edildiğin anda bildirim ekranında gör.
- **Karekod ile Güvenli Mesai:** "Kaçta başladım, kaçta çıktım?" derdi bitti. Telefonunla QR kodu okut, mesaini kendin başlat ve bitir.
- **Şeffaf Cüzdan ve Kazanç Takibi:** Kazandığın yevmiyeleri, tamamlanan işlerini ve cüzdan bakiyeni her an profilinden takip et.
- **İşvereni Puanla:** Çalışma ortamını, işletmenin yaklaşımını puanla; topluluğun güvenli kalmasına sen de katkı sun.

##  Teknolojik Altyapı

Bu proje, hem hızlı geliştirilebilirlik hem de düşük sistem gereksinimi düşünülerek yalın ve güçlü teknolojilerle inşa edildi:

| Katman | Teknoloji / Kütüphane | Ne İşe Yarar? |

| **Mobil Uygulama** | **Flutter (Dart 3.x)** | iOS, Android ve Masaüstü için ortak, akıcı ve modern kullanıcı deneyimi. |
| **Durum & Saklama** | **SharedPreferences** | Kullanıcı oturumu, rol ve yerel tercihlerin güvenli tutulması. |
| **Kamera & QR** | **mobile_scanner & qr_flutter** | Işık hızında QR kod üretimi ve kamera okuması. |
| **Sunucu (Backend)** | **PHP 8+ (PDO, REST API)** | Hafif, hızlı ve yapılandırması kolay arka uç servisleri. |
| **Veritabanı** | **MySQL / MariaDB (utf8mb4)** | İlişkisel, Türkçe karakter dostu veri mimarisi. |
| **Test Kolaylaştırıcı**| **ADB Port Tunneling & Seeder** | Gerçek cihazlarda ve emülatörde sıfır eforla canlı test imkanı. |

---

##  Proje Dizin Yapısı

Merak edenler için mutfağın yerleşim planı:

```
okul_proje/
├── lib/
│   ├── main.dart                  # Uygulamanın giriş noktası ve tema sarmalayıcısı
│   ├── home_screen.dart           # Rol bazlı ana kontrol paneli (İlanlar / Profil / Geçmiş)
│   ├── jobs_list_screen.dart      # İlan listesi ve filtreleme arayüzü
│   ├── add_job_screen.dart        # İşveren için yeni ilan oluşturma formu
│   ├── applications_screen.dart   # Gelen / giden başvuruların yönetimi
│   ├── qr_generate_screen.dart    # İşe başlama ve bitirme için dinamik QR üretici
│   ├── qr_scan_screen.dart        # Kamera ile QR tarama ekranı
│   ├── auth_service.dart          # Kimlik doğrulama, oturum ve cüzdan API köprüsü
│   ├── job_service.dart           # İlan ve başvuru işlemleri servisi
│   ├── server_config.dart         # Akıllı yerel IP ve sunucu adresi yönetimi
│   ├── theme/                     # Açık ve koyu tema tanımları
│   └── widgets/                   # Özel butonlar, dialoglar, telefon formatlayıcı vb.
│
├── backend/                       # PHP REST API Dosyaları
│   ├── db.php                     # Güvenli PDO veritabanı bağlantısı ve sanitization
│   ├── seed.php                   # Tabloları kuran ve test verisi basan sihirli dosya
│   ├── login.php / register.php   # Kullanıcı kimlik doğrulama uç noktaları
│   ├── get_jobs.php / add_job.php # İlan okuma ve oluşturma servisleri
│   ├── check_status.php           # QR durumunu dinleyen anlık yoklama (polling)
│   └── submit_review.php          # Karşılıklı puan ve yorum kayıt servisi
│
├── assets/                        # Uygulama ikonları ve görsel materyaller
└── USB_TUNELI_AC.bat              # Canlı sunumlar için tek tıkla USB tünel yardımcısı
```

##  Katkıda Bulunmak İster misin?

Bu proje bir fikirle, bir fincan kahveyle ve öğrenme tutkusuyla başladı.  
Her türlü fikre, geri bildirime ve `Pull Request`'e kapımız sonuna kadar açık:

1. Bu depoyu çatalla (Fork).
2. Özellik dalını oluştur (`git checkout -b ozellik/harika-bir-fikir`).
3. Değişikliklerini kaydet (`git commit -m 'feat: Harika bir özellik eklendi'`).
4. Dalına gönder (`git push origin ozellik/harika-bir-fikir`).
5. Bir **Pull Request** aç, birlikte inceleyelim!
