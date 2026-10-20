import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Boş durum türleri.
/// İleride hazırlayacağınız özel illüstrasyonları (SVG / Lottie / PNG)
/// bu tür bazında tek bir merkezden kolayca bağlayabilirsiniz.
enum EmptyStateType {
  /// İşçi için henüz açık ilan olmaması durumu
  noJobs,

  /// Seçili meslek/ilçe filtrelerine uyan ilan bulunamaması
  noMatchingJobs,

  /// İşverenin henüz hiç ilan yayınlamamış olması
  noEmployerJobs,

  /// İşçinin henüz aktif bir başvurusunun bulunmaması
  noApplications,

  /// Geçmiş işlemler veya tamamlanan işler listesinin boş olması
  noHistory,

  /// Profilde henüz yorum/değerlendirme bulunmaması
  noReviews,

  /// Bir ilana henüz başvuru gelmemiş olması (işveren görünümü)
  noApplicants,

  /// Genel veya özelleştirilmiş boş durum
  general,
}

/// Tüm liste ekranlarında ve kart içi boş durumlarda kullanılan,
/// gelecekteki özel illüstrasyon/animasyon entegrasyonuna hazır boş durum bileşeni.
class EmptyStateView extends StatelessWidget {
  /// Boş durum türü (Örn: `EmptyStateType.noJobs`)
  final EmptyStateType type;

  /// Ana başlık (Örn: "Henüz İlan Bulunmuyor")
  final String title;

  /// Açıklayıcı alt metin
  final String? message;

  /// Yedek ikon (Özel illüstrasyon tanımlı değilse bu modern ikon gösterilir)
  final IconData? icon;

  /// Özel ikon rengi (Boş bırakılırsa temaya göre otomatik belirlenir)
  final Color? iconColor;

  /// İkon arka plan rengi
  final Color? iconBackgroundColor;

  /// Varsa yerel görsel yolu (Örn: 'assets/images/empty_jobs.png')
  final String? imageAsset;

  /// Bu tekil widget örneği için doğrudan verilebilecek özel çizim / widget (Lottie, SVG vb.)
  final Widget? customIllustration;

  /// Birincil aksiyon butonu metni (Örn: "Filtreleri Temizle", "Yeni İlan Ver")
  final String? actionLabel;

  /// Birincil aksiyon butonuna basıldığında tetiklenecek fonksiyon
  final VoidCallback? onActionPressed;

  /// Birincil aksiyon butonu ikonu
  final IconData? actionIcon;

  /// İkincil aksiyon butonu metni
  final String? secondaryActionLabel;

  /// İkincil aksiyon butonuna basıldığında tetiklenecek fonksiyon
  final VoidCallback? onSecondaryActionPressed;

  /// Kart içleri veya küçük bölümler için kompakt mod (daha az padding ve küçük ikon)
  final bool isCompact;

  /// Pull-to-refresh (AppRefreshIndicator) ile tam uyumlu olması için kaydırılabilir olma durumu
  final bool isScrollable;

  /// =========================================================================
  /// GLOBAL İLLÜSTRASYON ENTEGRASYON NOKTASI:
  /// İleride hazırladığınız özel tasarımları (SVG, Lottie veya PNG), her ekranı
  /// tek tek değiştirmeden tek bir noktadan uygulamaya bağlamak için
  /// `EmptyStateView.globalIllustrationBuilder` fonksiyonuna atama yapabilirsiniz.
  ///
  /// Örnek Kullanım:
  /// ```dart
  /// EmptyStateView.globalIllustrationBuilder = (context, type) {
  ///   switch (type) {
  ///     case EmptyStateType.noJobs:
  ///       return Image.asset('assets/illustrations/no_jobs.png', height: 160);
  ///     case EmptyStateType.noMatchingJobs:
  ///       return SvgPicture.asset('assets/illustrations/filter_empty.svg', height: 160);
  ///     ...
  ///   }
  /// };
  /// ```
  /// =========================================================================
  static Widget Function(BuildContext context, EmptyStateType type)? globalIllustrationBuilder;

  const EmptyStateView({
    super.key,
    this.type = EmptyStateType.general,
    required this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.imageAsset,
    this.customIllustration,
    this.actionLabel,
    this.onActionPressed,
    this.actionIcon,
    this.secondaryActionLabel,
    this.onSecondaryActionPressed,
    this.isCompact = false,
    this.isScrollable = true,
  });

  /// 1. Aktif iş ilanı bulunamadığında (İşçi görünümü)
  factory EmptyStateView.noJobs({
    Key? key,
    VoidCallback? onRefresh,
    Widget? customIllustration,
    String? imageAsset,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.noJobs,
      icon: Icons.work_outline_rounded,
      title: 'Aktif İlan Bulunmuyor',
      message: 'Şu anda yayında olan açık bir iş ilanı yok. Yeni fırsatlar eklendikçe burada listelenecektir.',
      actionLabel: onRefresh != null ? 'Sayfayı Yenile' : null,
      actionIcon: Icons.refresh_rounded,
      onActionPressed: onRefresh,
      customIllustration: customIllustration,
      imageAsset: imageAsset,
    );
  }

  /// 2. Filtre veya arama sonucunda ilan bulunamadığında
  factory EmptyStateView.noMatchingJobs({
    Key? key,
    VoidCallback? onClearFilters,
    Widget? customIllustration,
    String? imageAsset,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.noMatchingJobs,
      icon: Icons.filter_alt_off_rounded,
      title: 'Aramana Uygun İlan Yok',
      message: 'Seçtiğin meslek veya ilçe kriterlerine uygun ilan bulunamadı. Filtreleri temizleyerek tüm ilanları görebilirsin.',
      actionLabel: onClearFilters != null ? 'Filtreleri Temizle' : null,
      actionIcon: Icons.clear_all_rounded,
      onActionPressed: onClearFilters,
      customIllustration: customIllustration,
      imageAsset: imageAsset,
    );
  }

  /// 3. İşverenin henüz hiç aktif ilanı olmadığında
  factory EmptyStateView.noEmployerJobs({
    Key? key,
    VoidCallback? onAddJob,
    Widget? customIllustration,
    String? imageAsset,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.noEmployerJobs,
      icon: Icons.post_add_rounded,
      title: 'Henüz İlan Yayınlamadınız',
      message: 'İhtiyacınız olan yevmiyecilere ve çalışanlara hızla ulaşmak için hemen ilk iş ilanınızı oluşturun.',
      actionLabel: onAddJob != null ? 'Yeni İlan Oluştur' : null,
      actionIcon: Icons.add_rounded,
      onActionPressed: onAddJob,
      customIllustration: customIllustration,
      imageAsset: imageAsset,
    );
  }

  /// 4. İşçinin henüz başvurusu olmadığında
  factory EmptyStateView.noApplications({
    Key? key,
    VoidCallback? onExploreJobs,
    Widget? customIllustration,
    String? imageAsset,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.noApplications,
      icon: Icons.assignment_outlined,
      title: 'Henüz Bir Başvurunuz Yok',
      message: 'Günlük ve dönemsel iş fırsatlarına göz atarak size uygun işlere hemen başvurabilirsiniz.',
      actionLabel: onExploreJobs != null ? 'İlanları Keşfet' : null,
      actionIcon: Icons.search_rounded,
      onActionPressed: onExploreJobs,
      customIllustration: customIllustration,
      imageAsset: imageAsset,
    );
  }

  /// 5. Geçmiş işlem veya tamamlanan işler boş olduğunda
  factory EmptyStateView.noHistory({
    Key? key,
    String? message,
    Widget? customIllustration,
    String? imageAsset,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.noHistory,
      icon: Icons.history_rounded,
      title: 'Geçmiş İşlem Bulunmuyor',
      message: message ?? 'Tamamlanan, onaylanan veya arşivlenen iş geçmişiniz burada listelenecektir.',
      customIllustration: customIllustration,
      imageAsset: imageAsset,
    );
  }

  /// 6. Profilde veya işte değerlendirme/yorum bulunmadığında
  factory EmptyStateView.noReviews({
    Key? key,
    bool isCompact = true,
    Widget? customIllustration,
    String? imageAsset,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.noReviews,
      icon: Icons.rate_review_outlined,
      title: 'Henüz Değerlendirme Yok',
      message: 'Tamamlanan işlerin ardından işverenlerin yaptığı puanlar ve yorumlar burada görünecektir.',
      isCompact: isCompact,
      isScrollable: false,
      customIllustration: customIllustration,
      imageAsset: imageAsset,
    );
  }

  /// 7. İşverenin ilanına henüz başvuru gelmediğinde (Kart içi kompakt görünüm)
  factory EmptyStateView.noApplicants({
    Key? key,
    Widget? customIllustration,
    String? imageAsset,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.noApplicants,
      icon: Icons.group_off_rounded,
      title: 'Henüz Başvuru Yok',
      message: 'Bu ilan için henüz bir yevmiyeci başvurusu alınmadı.',
      isCompact: true,
      isScrollable: false,
      customIllustration: customIllustration,
      imageAsset: imageAsset,
    );
  }

  /// 8. Özelleştirilebilir genel kompakt boş durum
  factory EmptyStateView.compact({
    Key? key,
    required String title,
    String? message,
    IconData icon = Icons.info_outline_rounded,
    Widget? customIllustration,
  }) {
    return EmptyStateView(
      key: key,
      type: EmptyStateType.general,
      icon: icon,
      title: title,
      message: message,
      isCompact: true,
      isScrollable: false,
      customIllustration: customIllustration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget content = _buildContent(context, isDark);

    if (isCompact || !isScrollable) {
      return content;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 300,
            ),
            child: Center(
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (isCompact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E232B) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIllustration(context, isDark, isCompactSize: true),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.3,
                ),
              ),
            ],
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onActionPressed,
                icon: actionIcon != null ? Icon(actionIcon, size: 16) : const SizedBox.shrink(),
                label: Text(actionLabel!),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: primaryColor,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIllustration(context, isDark, isCompactSize: false),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: actionIcon != null ? Icon(actionIcon, size: 18) : const SizedBox.shrink(),
              label: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimary : const Color(0xFF111827),
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryActionPressed != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondaryActionPressed,
              child: Text(
                secondaryActionLabel!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// İllüstrasyon veya ikon oluşturma sırası:
  /// 1. `customIllustration` (Bileşene doğrudan geçilen widget)
  /// 2. `globalIllustrationBuilder` (İleride ekleyeceğiniz merkezi çizim/Lottie fonksiyonu)
  /// 3. `imageAsset` (Görsel asset dosya yolu)
  /// 4. Varsayılan modern dairesel ikon kutusu
  Widget _buildIllustration(BuildContext context, bool isDark, {required bool isCompactSize}) {
    if (customIllustration != null) {
      return customIllustration!;
    }

    if (globalIllustrationBuilder != null) {
      final customBuilt = globalIllustrationBuilder!(context, type);
      return customBuilt;
    }

    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(
        imageAsset!,
        height: isCompactSize ? 60 : 140,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(isDark, isCompactSize),
      );
    }

    return _buildDefaultIcon(isDark, isCompactSize);
  }

  Widget _buildDefaultIcon(bool isDark, bool isCompactSize) {
    final double boxSize = isCompactSize ? 48.0 : 88.0;
    final double iconSize = isCompactSize ? 24.0 : 42.0;

    final effectiveIconColor = iconColor ??
        (isDark ? AppColors.darkPrimary : const Color(0xFF111827));

    final effectiveBgColor = iconBackgroundColor ??
        (isDark
            ? AppColors.darkPrimary.withOpacity(0.12)
            : const Color(0xFF111827).withOpacity(0.06));

    final effectiveIcon = icon ?? Icons.inbox_rounded;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? AppColors.darkPrimary.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          effectiveIcon,
          size: iconSize,
          color: effectiveIconColor,
        ),
      ),
    );
  }
}
