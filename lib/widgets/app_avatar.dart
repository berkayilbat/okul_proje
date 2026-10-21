import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../utils/app_page_route.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final String? heroTag;
  final bool showEditBadge;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onEditBadgeTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderWidth;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.heroTag,
    this.showEditBadge = false,
    this.isLoading = false,
    this.onTap,
    this.onEditBadgeTap,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
  });

  static String computeInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildFallback(
    BuildContext context,
    Color bg,
    Color fg,
    double fontSize,
  ) {
    final initials = computeInitials(name);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: fg,
                letterSpacing: -0.5,
              ),
            )
          : Icon(
              Icons.person,
              size: radius * 1.1,
              color: fg,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = foregroundColor ??
        (isDark ? const Color(0xFF3B82F6) : const Color(0xFF111827));
    final defaultBg = isDark
        ? const Color(0xFF1E232B)
        : primaryColor.withOpacity(0.1);
    final effectiveBg = backgroundColor ?? defaultBg;
    final double fontSize = radius * 0.72;

    final fullUrl = AuthService.getFullImageUrl(imageUrl);

    Widget content;
    if (fullUrl != null && fullUrl.isNotEmpty) {
      content = ClipOval(
        child: Image.network(
          fullUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: effectiveBg,
              child: Center(
                child: SizedBox(
                  width: radius * 0.6,
                  height: radius * 0.6,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(context, effectiveBg, primaryColor, fontSize);
          },
        ),
      );
    } else {
      content = _buildFallback(context, effectiveBg, primaryColor, fontSize);
    }

    if (borderWidth > 0 && borderColor != null) {
      content = Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: content,
      );
    }

    if (isLoading) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          content,
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: radius * 0.7,
                height: radius * 0.7,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      content = Hero(
        tag: heroTag!,
        createRectTween: AppHeroHelper.fadeInPlaceRectTween,
        flightShuttleBuilder: AppHeroHelper.flightShuttleBuilder,
        placeholderBuilder: (context, heroSize, child) => child,
        child: Material(
          type: MaterialType.transparency,
          child: content,
        ),
      );
    }

    if (onTap != null && !showEditBadge) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    if (!showEditBadge) {
      return content;
    }

    final badgeRadius = (radius * 0.35).clamp(12.0, 20.0);
    final iconSize = badgeRadius * 1.1;

    return GestureDetector(
      onTap: onTap ?? onEditBadgeTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          content,
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditBadgeTap ?? onTap,
              child: Container(
                width: badgeRadius * 2,
                height: badgeRadius * 2,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF0A49A6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: iconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
