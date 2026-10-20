import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/app_refresh_indicator.dart';
import 'package:my_app/theme/app_theme.dart';

void main() {
  group('AppRefreshIndicator Widget Tests', () {
    testWidgets('renders RefreshIndicator with correct light theme styling', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: AppRefreshIndicator(
              onRefresh: () async {
                refreshed = true;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        ),
      );

      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);

      final refreshWidget = tester.widget<RefreshIndicator>(refreshFinder);
      expect(refreshWidget.color, AppColors.lightPrimary);
      expect(refreshWidget.backgroundColor, Colors.white);

      // Perform fling/drag to trigger pull-to-refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, isTrue);
    });

    testWidgets('renders RefreshIndicator with correct dark theme styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: AppRefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Text('Dark Item 1'),
                ],
              ),
            ),
          ),
        ),
      );

      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);

      final refreshWidget = tester.widget<RefreshIndicator>(refreshFinder);
      expect(refreshWidget.color, AppColors.darkPrimary);
      expect(refreshWidget.backgroundColor, AppColors.darkCard);
    });
  });
}
