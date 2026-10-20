import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/shimmer_loading.dart';

void main() {
  group('2.2 — Shimmer & Skeleton Widget Tests', () {
    testWidgets('Shimmer and ShimmerBox render without errors in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Shimmer(
              child: Column(
                children: [
                  ShimmerBox(width: 100, height: 20),
                  ShimmerBox(width: 50, height: 50, shape: BoxShape.circle),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNWidgets(2));
      expect(find.byType(ShaderMask), findsOneWidget);

      // Advance animation slightly to verify transform interpolation
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Shimmer and ShimmerBox render properly in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Shimmer(
              child: ShimmerBox(width: 150, height: 30),
            ),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ShimmerBox), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('JobCardSkeleton contains expected skeleton boxes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JobCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(JobCardSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('ApplicationCardSkeleton contains expected skeleton boxes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApplicationCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(ApplicationCardSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('SkeletonListView.jobs renders given item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonListView.jobs(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(JobCardSkeleton), findsNWidgets(3));
    });

    testWidgets('SkeletonListView.applications renders given item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonListView.applications(itemCount: 2),
          ),
        ),
      );

      expect(find.byType(ApplicationCardSkeleton), findsNWidgets(2));
    });
  });
}
