import 'package:flutter/material.dart';

enum BannerVariant { warning, error, info, success }

/// 2.7 — Material Banner (Sabit Üst Durum Bildirim Çubuğu)
/// Kritik ve kalıcı durumlar için (çevrimdışı mod, sunucu hatası, profil onayı)
/// ekranın tepesinde sabitlenen ve kullanıcı aksiyon alana kadar duran bildirim.
class AppBanner {
  static void show({
    required BuildContext context,
    required String message,
    BannerVariant variant = BannerVariant.warning,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearMaterialBanners();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;
    Color iconColor;
    IconData icon;

    switch (variant) {
      case BannerVariant.warning:
        bgColor = isDark ? const Color(0xFF2E2008) : const Color(0xFFFEF3C7);
        textColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        iconColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case BannerVariant.error:
        bgColor = isDark ? const Color(0xFF2C1010) : const Color(0xFFFEE2E2);
        textColor = isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B);
        iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        icon = Icons.cloud_off_rounded;
        break;
      case BannerVariant.info:
        bgColor = isDark ? const Color(0xFF0F1E36) : const Color(0xFFDBEAFE);
        textColor = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF);
        iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        icon = Icons.info_outline_rounded;
        break;
      case BannerVariant.success:
        bgColor = isDark ? const Color(0xFF0C2417) : const Color(0xFFD1FAE5);
        textColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46);
        iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: bgColor,
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Icon(icon, color: iconColor, size: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 1,
        actions: [
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                messenger.clearMaterialBanners();
                onAction();
              },
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              messenger.clearMaterialBanners();
              if (onDismiss != null) onDismiss();
            },
            child: Text(
              'Kapat',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.clearMaterialBanners();
  }
}
