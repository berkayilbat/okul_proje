import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tüm listelerde ve kaydırılabilir ekranlarda tutarlı renk, arka plan,
/// tema ve kaydırma davranışı sağlayan standart Pull-to-Refresh bileşeni.
class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final double displacement;
  final double edgeOffset;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      strokeWidth: 2.5,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}
