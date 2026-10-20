import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

enum SnackBarVariant { success, error, warning, info }

/// 2.7 — Geri Bildirim Sistemi Köprüsü
/// Varsayılan olarak modern Floating Top Toast (`AppToast`) gösterir.
/// İstenirse `useToast = false` yapılarak klasik SnackBar moduna geçilebilir.
class AppSnackbar {
  static bool useToast = true;

  /// Başarılı işlem bildirimi
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (useToast) {
      AppToast.showSuccess(context, message, duration: duration);
    } else {
      _show(
        context: context,
        message: message,
        variant: SnackBarVariant.success,
        duration: duration,
      );
    }
  }

  /// Hata bildirimi (İsteğe bağlı Yeniden Dene butonu)
  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    String retryLabel = 'Yeniden Dene',
    Duration duration = const Duration(seconds: 4),
  }) {
    if (useToast) {
      AppToast.showError(
        context,
        message,
        onRetry: onRetry,
        retryLabel: retryLabel,
        duration: duration,
      );
    } else {
      _show(
        context: context,
        message: message,
        variant: SnackBarVariant.error,
        onRetry: onRetry,
        retryLabel: retryLabel,
        duration: duration,
      );
    }
  }

  /// Uyarı bildirimi
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (useToast) {
      AppToast.showWarning(context, message, duration: duration);
    } else {
      _show(
        context: context,
        message: message,
        variant: SnackBarVariant.warning,
        duration: duration,
      );
    }
  }

  /// Bilgilendirme bildirimi
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (useToast) {
      AppToast.showInfo(context, message, duration: duration);
    } else {
      _show(
        context: context,
        message: message,
        variant: SnackBarVariant.info,
        duration: duration,
      );
    }
  }

  static void _show({
    required BuildContext context,
    required String message,
    required SnackBarVariant variant,
    VoidCallback? onRetry,
    String retryLabel = 'Yeniden Dene',
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Önceki açık kalan SnackBar varsa temizle
    messenger.hideCurrentSnackBar();

    Color bgColor;
    IconData icon;

    switch (variant) {
      case SnackBarVariant.success:
        bgColor = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SnackBarVariant.error:
        bgColor = AppColors.error;
        icon = Icons.error_outline_rounded;
        break;
      case SnackBarVariant.warning:
        bgColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case SnackBarVariant.info:
        bgColor = const Color(0xFF1E293B);
        icon = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: bgColor,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: retryLabel,
                textColor: Colors.white,
                backgroundColor: Colors.black.withValues(alpha: 0.25),
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
