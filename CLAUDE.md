# Yömyeci — Çalışma Kuralları

Günlük iş ilanı platformu: işveren ilan açar, çalışan başvurur, giriş/çıkış QR ile yapılır, ödeme sanal cüzdan üzerinden akar.
Yığın: Flutter (`lib/`) + Laravel 12 / MySQL 8 (`api/`, MAMP). Kimlik doğrulama: Laravel Sanctum (Bearer token).
Geçiş: eski düz PHP arka uç (`backend/`) çalışan demo olarak korunur, dokunma. Uçlar `api/` altına taşınır, bittiğinde `backend/` silinir.
PHP/Composer: MAMP'tekiler (`/Applications/MAMP/bin/php/php8.3.30/bin/php`, `/Applications/MAMP/bin/php/composer`). `php` yol tanımlı değil.
Plan: Notion "Yömyeci Sprint Görevleri v2". Görev numaraları (1.3, 3.6 …) oradan gelir.

## Roller ve dosya sahipliği
Her dosyanın tek sahibi vardır. Başka rolün dosyasına gereksiz dokunma; gerekiyorsa raporda bildir.

| Rol | Sahip olduğu alan |
|---|---|
| Arka uç | `api/**` (eski `backend/**` yalnızca taşıma için okunur, değiştirilmez) |
| Flutter çekirdek | `lib/api/**`, `lib/*_service.dart`, `lib/models/**`, `lib/utils/**`, `lib/main.dart`, `lib/server_config.dart` |
| Flutter UI | `lib/*_screen.dart`, `lib/widgets/**`, `lib/theme/**` |
| Test ve kalite | `test/**`, `api/tests/**`, `.github/**` |

Rolünü görev mesajının ilk satırı söyler. Söylemiyorsa sor.

## Sabit kurallar
- Yalnızca görevde istenen işi yap. "Bu arada şunu da düzelttim" yok; fark ettiklerini raporla.
- Belirsizlik varsa tahmin etme, soru olarak raporla.
- Bitirmeden ilgili testleri çalıştır (`flutter test`, `php artisan test` içinde `api/`). Çalıştıramadıysan bunu açıkça yaz.
- Laravel kodunu öğrenen biri okuyacak: her görevin raporuna "Ne yaptım ve neden" bölümü ekle, kullandığın Laravel kavramlarını (route, controller, migration, policy …) 1–2 cümleyle açıkla.
- `git push`, dal birleştirme, `git reset --hard`, veri silme yapma. Commit'i kendi dalına at.
- `GEMINI.md` ve `.agents/` eski bir ajandan kalma, yok say.
- Sırları (şifre, anahtar) koda veya commit mesajına yazma.

## Kod
- Mevcut kodun üslubuna uy (isimlendirme, yorum yoğunluğu, Türkçe kullanıcı metinleri).
- Para, yetki ve QR akışlarında sunucu tek doğruluk kaynağıdır; istemci tarafı kontrol güvenlik sayılmaz.
- Para hareketleri tek transaction içinde, tekrar çağrıya dayanıklı olmalı.
- Veritabanı değişikliği Laravel migration'ıyla yapılır, elle SQL çalıştırılmaz. Demo verisi seeder'dadır.
- Yeni API'nin yanıtları mümkün olduğunca eski `backend/` ile aynı JSON alanlarını korur (`status`, `message`, `data`), böylece Flutter ekranları bozulmaz.
- Yeni arka uç ayrı veritabanı kullanır (`yomyeci_v2`); eski `my_app_db` demo için kalır.
- Uzun veya ortak API tanımları `docs/api/` altındadır; prompt'ta yolu verilir, orayı oku.

## Commit
`feat|fix|refactor|test(alan): <görev no> — kısa açıklama` (örn. `feat(backend): 1.3 — token tabanlı kimlik doğrulama`).
Küçük, tek amaçlı commit'ler at.

## Rapor formatı (iş bitince)
1. Yapılan: değişen dosyalar, 3–5 madde.
2. Doğrulama: çalıştırılan komutlar ve sonuçları (geçti/kaldı).
3. Yapılamayan veya riskli: eksikler, varsayımlar.
4. Başka rolden beklenen: bağımlılıklar veya sorular.
