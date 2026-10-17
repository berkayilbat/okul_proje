import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kullanıcının referans görselindeki tasarıma birebir uyan
/// kayan dairesel butonlu, siyah-beyaz, çift ikonlu (Güneş / Hilal-Yıldızlar)
/// animasyonlu kapsül tema geçiş anahtarı (Switch Toggle).
class AnimatedThemeToggle extends StatelessWidget {
  final double? width;
  final double? height;
  final double? size;
  final VoidCallback? onToggled;

  const AnimatedThemeToggle({
    super.key,
    this.width,
    this.height,
    this.size,
    this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    // Oranlar: yükseklik 32 iken genişlik yaklaşık 62-64 dp
    final double h = height ?? size ?? 32.0;
    final double w = width ?? (size != null ? size! * 1.88 : 62.0);
    const double padding = 3.0;
    final double thumbSize = h - (padding * 2);
    final double iconSize = thumbSize * 0.65;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return Tooltip(
          message: isDark ? 'Açık Moda Geç' : 'Karanlık Moda Geç',
          child: GestureDetector(
            onTap: () {
              ThemeController.toggleTheme();
              onToggled?.call();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              width: w,
              height: h,
              padding: const EdgeInsets.all(padding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(h / 2),
                // Referans Görsel: Koyu modda siyah/antrasit (#1E1E1E), Açık modda açık gümüş/gri (#E5E7EB)
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E32) : const Color(0xFFD4D4D8),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sol Slot: Güneş ikonu (Açık modda görünür, karanlık modda beyaz thumb üstünü örter)
                  Positioned(
                    left: (w / 4) - (iconSize / 2) - padding,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isDark ? 0.0 : 1.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: isDark ? 0.6 : 1.0,
                        child: Icon(
                          Icons.wb_sunny_outlined,
                          size: iconSize,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ),

                  // Sağ Slot: Hilal ve yıldızlar ikonu (Karanlık modda görünür, açık modda siyah thumb üstünü örter)
                  Positioned(
                    right: (w / 4) - (iconSize / 2) - padding,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isDark ? 1.0 : 0.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: isDark ? 1.0 : 0.6,
                        child: Icon(
                          Icons.nights_stay_rounded,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Kayan Dairesel Buton (Thumb Slider)
                  // Karanlık modda sol tarafta (beyaz daire)
                  // Açık modda sağ tarafta (siyah daire)
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Profil ekranı için siyah-beyaz, temaya ve toggle'a uyumlu animasyonlu çıkış butonu
class AnimatedLogoutButton extends StatefulWidget {
  final double size;
  final VoidCallback onLogout;

  const AnimatedLogoutButton({
    super.key,
    this.size = 32.0,
    required this.onLogout,
  });

  @override
  State<AnimatedLogoutButton> createState() => _AnimatedLogoutButtonState();
}

class _AnimatedLogoutButtonState extends State<AnimatedLogoutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.12, 0.0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return Tooltip(
          message: 'Çıkış Yap',
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              widget.onLogout();
            },
            onTapCancel: () => _controller.reverse(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                width: widget.size,
                height: widget.size,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Tema toggle ile birebir uyumlu renkler
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E32) : const Color(0xFFD4D4D8),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Icon(
                      Icons.logout_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      size: widget.size * 0.52,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Profil ekranına yerleştirilecek, tıklanabilir animasyonlu ayar kartı
class ThemeSettingCard extends StatelessWidget {
  const ThemeSettingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final cardColor = isDark ? AppColors.darkCard : Colors.white;
        final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;
        final titleColor = isDark ? AppColors.darkTextPrimary : Colors.black87;
        final subtitleColor = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E32) : const Color(0xFFD4D4D8),
                  ),
                ),
                child: Icon(
                  isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_outlined,
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Karanlık Mod',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Karanlık Tema Aktif' : 'Açık Tema Aktif',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const AnimatedThemeToggle(width: 62, height: 32),
            ],
          ),
        );
      },
    );
  }
}
