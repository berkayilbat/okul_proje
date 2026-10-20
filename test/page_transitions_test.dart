import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/app_page_route.dart';
import 'package:my_app/job_detail_screen.dart';

void main() {
  group('2.5 — AppPageRoute Tests', () {
    testWidgets('AppPageRoute.hero builds PageRoute with FadeTransition', (WidgetTester tester) async {
      final route = AppPageRoute.hero(
        const Scaffold(body: Text('Hero Target Page')),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => route,
        ),
      );

      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.text('Hero Target Page'), findsOneWidget);
    });

    testWidgets('AppPageRoute.slideRight builds PageRoute with SlideTransition and FadeTransition', (WidgetTester tester) async {
      final route = AppPageRoute.slideRight(
        const Scaffold(body: Text('Slide Right Target')),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => route,
        ),
      );

      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.text('Slide Right Target'), findsOneWidget);
    });

    testWidgets('AppPageRoute.slideUp builds PageRoute with SlideTransition', (WidgetTester tester) async {
      final route = AppPageRoute.slideUp(
        const Scaffold(body: Text('Slide Up Target')),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => route,
        ),
      );

      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.text('Slide Up Target'), findsOneWidget);
    });

    testWidgets('AppPageRoute.fadeThrough builds PageRoute with ScaleTransition and FadeTransition', (WidgetTester tester) async {
      final route = AppPageRoute.fadeThrough(
        const Scaffold(body: Text('Fade Through Target')),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => route,
        ),
      );

      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.text('Fade Through Target'), findsOneWidget);
    });

    testWidgets('SmoothPageTransitionsBuilder builds valid transitions', (WidgetTester tester) async {
      const builder = SmoothPageTransitionsBuilder();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: builder,
              },
            ),
          ),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(body: Text('Pushed Screen')),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      expect(find.text('Go'), findsOneWidget);
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.text('Pushed Screen'), findsOneWidget);
    });
  });

  group('2.5 — JobDetailScreen Hero & Details Tests', () {
    final mockJob = {
      'id': 101,
      'title': 'Garson / Barista',
      'wage': 750,
      'location': 'Kadıköy, İstanbul',
      'working_hours': '09:00 - 18:00',
      'dates': '22 Ekim 2026',
      'description': 'Kafemizde hafta sonu çalışacak deneyimli garson aranıyor.',
      'employer_phone': '05551234567',
    };

    testWidgets('JobDetailScreen renders Hero widgets for title and wage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: mockJob,
            isEmployer: false,
            hasApplied: false,
          ),
        ),
      );

      // Verify title hero
      final titleHero = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'job-title-101',
      );
      expect(titleHero, findsOneWidget);

      // Verify wage hero
      final wageHero = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'job-wage-101',
      );
      expect(wageHero, findsOneWidget);

      // Verify key details
      expect(find.text('GARSON / BARISTA'), findsOneWidget);
      expect(find.text('750₺'), findsWidgets);
      expect(find.text('Kadıköy, İstanbul'), findsOneWidget);
      expect(find.text('09:00 - 18:00'), findsOneWidget);
      expect(find.text('22 Ekim 2026'), findsOneWidget);
      expect(find.text('Hemen Başvur (750₺)'), findsOneWidget);
    });

    testWidgets('JobDetailScreen shows applied state when hasApplied is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: mockJob,
            isEmployer: false,
            hasApplied: true,
          ),
        ),
      );

      expect(find.text('Bu İlana Başvuruldu'), findsOneWidget);
    });

    testWidgets('JobDetailScreen hides apply button for employer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: mockJob,
            isEmployer: true,
            hasApplied: false,
          ),
        ),
      );

      expect(find.text('Hemen Başvur (750₺)'), findsNothing);
      expect(find.text('Bu İlana Başvuruldu'), findsNothing);
    });
  });
}
