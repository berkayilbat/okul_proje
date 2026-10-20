import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/empty_state_view.dart';

void main() {
  tearDown(() {
    EmptyStateView.globalIllustrationBuilder = null;
  });

  group('2.1 — EmptyStateView Widget Tests', () {
    testWidgets('EmptyStateView.noJobs renders correctly with refresh action', (WidgetTester tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.noJobs(
              onRefresh: () => refreshed = true,
            ),
          ),
        ),
      );

      expect(find.text('Aktif İlan Bulunmuyor'), findsOneWidget);
      expect(find.textContaining('açık bir iş ilanı yok'), findsOneWidget);
      expect(find.text('Sayfayı Yenile'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Sayfayı Yenile'));
      await tester.pump();
      expect(refreshed, isTrue);
    });

    testWidgets('EmptyStateView.noMatchingJobs renders and triggers onClearFilters', (WidgetTester tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.noMatchingJobs(
              onClearFilters: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('Aramana Uygun İlan Yok'), findsOneWidget);
      expect(find.textContaining('Filtreleri temizleyerek'), findsOneWidget);
      expect(find.text('Filtreleri Temizle'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_off_rounded), findsOneWidget);

      await tester.tap(find.text('Filtreleri Temizle'));
      await tester.pump();
      expect(cleared, isTrue);
    });

    testWidgets('EmptyStateView.noEmployerJobs renders with create job action', (WidgetTester tester) async {
      bool jobCreated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.noEmployerJobs(
              onAddJob: () => jobCreated = true,
            ),
          ),
        ),
      );

      expect(find.text('Henüz İlan Yayınlamadınız'), findsOneWidget);
      expect(find.text('Yeni İlan Oluştur'), findsOneWidget);

      await tester.tap(find.text('Yeni İlan Oluştur'));
      await tester.pump();
      expect(jobCreated, isTrue);
    });

    testWidgets('EmptyStateView.noApplications renders and triggers onExploreJobs', (WidgetTester tester) async {
      bool explored = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.noApplications(
              onExploreJobs: () => explored = true,
            ),
          ),
        ),
      );

      expect(find.text('Henüz Bir Başvurunuz Yok'), findsOneWidget);
      expect(find.text('İlanları Keşfet'), findsOneWidget);

      await tester.tap(find.text('İlanları Keşfet'));
      await tester.pump();
      expect(explored, isTrue);
    });

    testWidgets('EmptyStateView.noHistory and noReviews compact modes render', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EmptyStateView.noHistory(),
                EmptyStateView.noReviews(isCompact: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Geçmiş İşlem Bulunmuyor'), findsOneWidget);
      expect(find.text('Henüz Değerlendirme Yok'), findsOneWidget);
    });

    testWidgets('customIllustration widget replaces default icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.noJobs(
              customIllustration: const KeyedSubtree(
                key: ValueKey('my_custom_svg_mock'),
                child: Text('Custom SVG Art'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('my_custom_svg_mock')), findsOneWidget);
      expect(find.text('Custom SVG Art'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline_rounded), findsNothing);
    });

    testWidgets('EmptyStateView.globalIllustrationBuilder dynamically injects custom designs', (WidgetTester tester) async {
      EmptyStateView.globalIllustrationBuilder = (context, type) {
        if (type == EmptyStateType.noJobs) {
          return const Text('GLOBAL_CUSTOM_JOBS_ILLUSTRATION');
        }
        return const SizedBox();
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.noJobs(),
          ),
        ),
      );

      expect(find.text('GLOBAL_CUSTOM_JOBS_ILLUSTRATION'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline_rounded), findsNothing);
    });
  });
}
