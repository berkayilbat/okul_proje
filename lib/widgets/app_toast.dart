import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ToastVariant { success, error, warning, info }

/// 2.7 — Modern Floating Top Toast (Dynamic Island / Kapsül Bildirim Sistemi)
/// Ekranın üstünden yaylanarak inen, alttaki buton ve menüleri engellemeyen,
/// dokunularak veya yukarı kaydırılarak anında kapatılabilen modern bildirim kapsülü.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Başarı bildirimi (Zümrüt Yeşili, Onay Rozeti)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(
      context: context,
      message: message,
      variant: ToastVariant.success,
      duration: duration,
    );
  }

  /// Hata bildirimi (Kırmızı, Hata Rozeti, İsteğe bağlı Yeniden Dene butonu)
  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    String retryLabel = 'Yeniden Dene',
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    show(
      context: context,
      message: message,
      variant: ToastVariant.error,
      onRetry: onRetry,
      retryLabel: retryLabel,
      duration: duration,
    );
  }

  /// Uyarı bildirimi (Amber / Turuncu, Uyarı Rozeti)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context: context,
      message: message,
      variant: ToastVariant.warning,
      duration: duration,
    );
  }

  /// Bilgilendirme bildirimi (Mavi / Slate, Bilgi Rozeti)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(
      context: context,
      message: message,
      variant: ToastVariant.info,
      duration: duration,
    );
  }

  /// Açık olan toast'ı hemen kapatır
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      _currentEntry?.remove();
      _currentEntry = null;
    }
  }

  /// Genel gösterim metodu
  static void show({
    required BuildContext context,
    required String message,
    required ToastVariant variant,
    VoidCallback? onRetry,
    String retryLabel = 'Yeniden Dene',
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    // Haptik geri bildirim
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    // Önceki toast varsa temizle
    dismiss();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        variant: variant,
        onRetry: onRetry,
        retryLabel: retryLabel,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            dismiss();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        dismiss();
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastVariant variant;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.variant,
    this.onRetry,
    required this.retryLabel,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_controller);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 10;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color variantColor;
    IconData icon;

    switch (widget.variant) {
      case ToastVariant.success:
        variantColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
        icon = Icons.check_circle_rounded;
        break;
      case ToastVariant.error:
        variantColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        icon = Icons.error_rounded;
        break;
      case ToastVariant.warning:
        variantColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        icon = Icons.warning_rounded;
        break;
      case ToastVariant.info:
        variantColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        icon = Icons.info_rounded;
        break;
    }

    final cardBg = isDark ? const Color(0xFF16191E) : Colors.white;
    final cardBorder = isDark
        ? variantColor.withValues(alpha: 0.35)
        : variantColor.withValues(alpha: 0.3);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const Key('app_toast_dismissible'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: InkWell(
                    onTap: _handleDismiss,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: variantColor.withValues(alpha: isDark ? 0.12 : 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Sol İkon Rozeti
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: variantColor.withValues(alpha: isDark ? 0.18 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: variantColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          // Mesaj
                          Expanded(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          // Yeniden Dene Butonu
                          if (widget.onRetry != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: variantColor.withValues(alpha: 0.12),
                                foregroundColor: variantColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                _handleDismiss();
                                widget.onRetry!();
                              },
                              child: Text(
                                widget.retryLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          // Kapatma Çarpısı
                          GestureDetector(
                            onTap: _handleDismiss,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
