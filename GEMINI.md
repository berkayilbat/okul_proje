# Proje Kuralları ve Yönergeleri

## Git Sürüm Senkronizasyonu Hatırlatıcısı (Zorunlu Kural)

- Bu proje kapsamında kullanıcı herhangi bir sohbette komut, soru veya talep girdiğinde:
  - Yerel cihazdaki kodun GitHub'daki son commit ile aynı versiyonda olup olmadığını daima göz önünde bulundur.
  - Sistem tarafından sağlanan Git bildirimlerini dikkate al veya şüphe durumunda yerel durum ile remote durumunu (`git status` / `git rev-parse`) kontrol et.
  - Eğer yerel kod GitHub'daki (origin) son commit ile aynı versiyonda değilse (örneğin geride kalmışsa veya diverged durumdaysa):
    - **Kullanıcıya vereceğin yanıtın en başında**, yerel kodun GitHub'daki güncel versiyonla eşleşmediğini ve çalışmaya devam etmeden önce kodunu `git pull` ile güncellemesi gerektiğini **MUTLAKA** vurgula.

## Proje Tamamlama ve Fazlalık Dosyaları Temizleme Kuralı

- Kullanıcı proje tamamlanma sürecinde herhangi bir sohbette geliştirme aşamasından kalan fazlalık/geçici dosyaların temizlenmesini istediğinde:
  - Git senkronizasyonu ve geliştirme takibi için oluşturulan şu dosyaları/dizinleri de **MUTLAKA** hatırla ve temizlenecek dosyalar listesine dahil et:
    - [`.agents/hooks.json`](file:///Users/emre/StudioProjects/okul_proje/.agents/hooks.json)
    - [`.agents/scripts/check_git_sync.py`](file:///Users/emre/StudioProjects/okul_proje/.agents/scripts/check_git_sync.py) (veya tüm [`.agents/`](file:///Users/emre/StudioProjects/okul_proje/.agents/) klasörü)
    - [`GEMINI.md`](file:///Users/emre/StudioProjects/okul_proje/GEMINI.md) dosyasındaki ilgili geliştirme kuralları
