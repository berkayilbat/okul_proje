import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 2.2 — Skeleton / Shimmer Yükleniyor Efekti
///
/// Harici ağır kütüphanelere ihtiyaç duymadan, Flutter'ın yerleşik
/// [ShaderMask], [LinearGradient] ve [AnimationController] yapılarıyla
/// 60 FPS akıcı ve pil dostu olarak dalgalanan ışık (shimmer) efekti sağlar.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = widget.baseColor ??
        (isDark ? const Color(0xFF222832) : const Color(0xFFE5E7EB));
    final highlightColor = widget.highlightColor ??
        (isDark ? const Color(0xFF333E4E) : const Color(0xFFF9FAFB));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [
                0.0,
                0.5,
                1.0,
              ],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// İskelet kutucuğu (Metin satırları, ikonlar, chipler veya buton yer tutucuları için)
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222832) : const Color(0xFFE5E7EB),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// İş İlanı Kartı İskeleti (`JobsListScreen` için)
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Ücret Rozeti
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 160, height: 20, borderRadius: 6),
                ShimmerBox(width: 76, height: 28, borderRadius: 14),
              ],
            ),
            SizedBox(height: 14),
            // Konum Satırı
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                SizedBox(width: 6),
                ShimmerBox(width: 130, height: 14, borderRadius: 4),
              ],
            ),
            SizedBox(height: 10),
            // Saat ve Tarih Satırı
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                SizedBox(width: 6),
                ShimmerBox(width: 80, height: 13, borderRadius: 4),
                SizedBox(width: 16),
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                SizedBox(width: 6),
                ShimmerBox(width: 90, height: 13, borderRadius: 4),
              ],
            ),
            SizedBox(height: 16),
            // Etiket / Chip Satırı
            Row(
              children: [
                ShimmerBox(width: 84, height: 24, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerBox(width: 96, height: 24, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Başvuru Kartı İskeleti (`ApplicationsScreen` için)
class ApplicationCardSkeleton extends StatelessWidget {
  const ApplicationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Durum Rozeti
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 150, height: 20, borderRadius: 6),
                ShimmerBox(width: 90, height: 26, borderRadius: 13),
              ],
            ),
            SizedBox(height: 14),
            // İşveren / Şirket Bilgisi
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                SizedBox(width: 6),
                ShimmerBox(width: 140, height: 14, borderRadius: 4),
              ],
            ),
            SizedBox(height: 10),
            // Saat / Tarih Bilgisi
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                SizedBox(width: 6),
                ShimmerBox(width: 100, height: 13, borderRadius: 4),
              ],
            ),
            SizedBox(height: 16),
            // Aksiyon Butonu Yer Tutucusu
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShimmerBox(width: 110, height: 34, borderRadius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// İskelet Kart Listesi Görünümü
class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final Widget? item;
  final EdgeInsetsGeometry padding;

  const SkeletonListView({
    super.key,
    this.itemCount = 4,
    this.item,
    this.padding = const EdgeInsets.all(16),
  });

  factory SkeletonListView.jobs({Key? key, int itemCount = 4}) {
    return SkeletonListView(
      key: key,
      itemCount: itemCount,
      item: const JobCardSkeleton(),
    );
  }

  factory SkeletonListView.applications({Key? key, int itemCount = 4}) {
    return SkeletonListView(
      key: key,
      itemCount: itemCount,
      item: const ApplicationCardSkeleton(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => item ?? const JobCardSkeleton(),
    );
  }
}
