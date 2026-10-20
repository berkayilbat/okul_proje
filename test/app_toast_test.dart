import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/app_toast.dart';
import 'package:my_app/widgets/app_banner.dart';
import 'package:my_app/theme/app_theme.dart';

void main() {
  group('2.7 — AppToast Floating Island Tests', () {
    testWidgets('shows success top toast with check icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.showSuccess(context, 'Başvuru Gönderildi'),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Başvuru Gönderildi'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Close toast
      AppToast.dismiss();
      await tester.pump();
      expect(find.text('Başvuru Gönderildi'), findsNothing);
    });

    testWidgets('shows error top toast with retry action button', (WidgetTester tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.showError(
                  context,
                  'Bağlantı Hatası',
                  onRetry: () => retried = true,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Bağlantı Hatası'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      expect(find.text('Yeniden Dene'), findsOneWidget);

      await tester.tap(find.text('Yeniden Dene'));
      await tester.pump();
      expect(retried, isTrue);

      AppToast.dismiss();
      await tester.pump();
    });

    testWidgets('shows warning and info top toasts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppToast.showWarning(context, 'Eksik Bilgi'),
                    child: const Text('Show Warning'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppToast.showInfo(context, 'Yeni Bildirim'),
                    child: const Text('Show Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Warning
      await tester.tap(find.text('Show Warning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Eksik Bilgi'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);

      // Info replaces previous toast
      await tester.tap(find.text('Show Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Yeni Bildirim'), findsOneWidget);
      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
      expect(find.text('Eksik Bilgi'), findsNothing);

      AppToast.dismiss();
      await tester.pump();
    });

    testWidgets('dismisses top toast when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.showSuccess(context, 'Dokun ve Kapat'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Dokun ve Kapat'), findsOneWidget);

      // Tap on toast to dismiss
      await tester.tap(find.text('Dokun ve Kapat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Dokun ve Kapat'), findsNothing);
    });
  });

  group('2.7 — AppBanner Material Banner Tests', () {
    testWidgets('shows and hides MaterialBanner correctly', (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppBanner.show(
                      context: context,
                      message: 'İnternet bağlantısı kesildi',
                      variant: BannerVariant.error,
                      actionLabel: 'Tekrar Dene',
                      onAction: () => actionTriggered = true,
                    ),
                    child: const Text('Show Banner'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppBanner.hide(context),
                    child: const Text('Hide Banner'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('İnternet bağlantısı kesildi'), findsNothing);

      // Show
      await tester.tap(find.text('Show Banner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('İnternet bağlantısı kesildi'), findsOneWidget);
      expect(find.text('Tekrar Dene'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);

      // Action
      await tester.tap(find.text('Tekrar Dene'));
      await tester.pump();
      expect(actionTriggered, isTrue);

      // Hide
      await tester.tap(find.text('Hide Banner'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MaterialBanner), findsNothing);
    });
  });
}
