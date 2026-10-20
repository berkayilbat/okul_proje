import 'package:flutter/material.dart';

/// Yömyeci Özel Sayfa Geçiş Animasyonları Kütüphanesi
/// - Hero: Kartların detay sayfasına kesintisiz genişlemesi
/// - SlideRight: Yumuşak kavisli yatay kayma & fade (Curves.easeOutCubic)
/// - SlideUp: Modal ve form ekranları için alttan yaylanarak yükselme
/// - FadeThrough: Z-ekseni derinlikli fade (profil/ayarlar/sekmeler)
class AppPageRoute {
  static const Duration defaultDuration = Duration(milliseconds: 320);
  static const Duration modalDuration = Duration(milliseconds: 350);
  static const Duration fadeDuration = Duration(milliseconds: 280);

  /// 1. Hero Destekli Geçiş (Kart Büyümesi)
  /// İlan kartı veya kullanıcı profili gibi Hero elementleri barındıran
  /// sayfalarda pürüzsüz kart genişlemesi ve hafif fade sağlar.
  static Route<T> hero<T>(Widget page, {Duration duration = defaultDuration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        );
      },
    );
  }

  /// 2. Pürüzsüz Slide & Fade (Yatay Akış)
  /// Giriş -> Kayıt gibi hiyerarşik adımlarda sağdan hafif ofsetle kayma ve belirme.
  static Route<T> slideRight<T>(Widget page, {Duration duration = defaultDuration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0.25, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  /// 3. Modal Slide-Up (Alttan Yükselme)
  /// Yeni İlan Ekleme gibi aksiyon/form sayfalarında alttan yukarıya yaylanarak açılır.
  static Route<T> slideUp<T>(Widget page, {Duration duration = modalDuration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        );
      },
    );
  }

  /// 4. Fade Through (Derinlikli Z-Axis Ölçekleme)
  /// Profil, ayarlar ve sekmeler arası yön bağımsız geçişlerde derinlikli yumuşak geçiş.
  static Route<T> fadeThrough<T>(Widget page, {Duration duration = fadeDuration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(begin: 0.94, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        );
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }
}

/// Global PageTransitionsTheme için özel builder
/// Tüm standart Navigator.push çağrılarını varsayılan sert geçiş yerine
/// 60 FPS donanım hızlandırmalı yumuşak kayma & fade efektine dönüştürür.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: Curves.easeOut),
    );

    // Geriye çekilen önceki ekran için hafif solma ve sola kayma
    final secondarySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.08, 0.0),
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    final secondaryFade = Tween<double>(begin: 1.0, end: 0.65).chain(
      CurveTween(curve: Curves.easeOut),
    );

    return SlideTransition(
      position: secondaryAnimation.drive(secondarySlide),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(secondaryFade),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        ),
      ),
    );
  }
}
