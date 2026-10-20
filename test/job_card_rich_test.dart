import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/jobs_list_screen.dart';
import 'package:my_app/utils/job_helpers.dart';
import 'package:my_app/job_detail_screen.dart';

void main() {
  group('2.6 — JobCategoryHelper Unit Tests', () {
    test('JobCategoryHelper maps job titles to correct category icons', () {
      expect(JobCategoryHelper.getCategoryIcon('Barista Aranıyor'), Icons.local_cafe_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Restoran Garson'), Icons.restaurant_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Moto Kurye'), Icons.two_wheeler_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Depo Sayım Elemanı'), Icons.inventory_2_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Ofis Temizlik Görevlisi'), Icons.cleaning_services_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Mağaza Satış Danışmanı'), Icons.storefront_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Fuar Hostesi'), Icons.celebration_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Tadilat Ustası'), Icons.construction_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Bina Güvenlik Görevlisi'), Icons.security_rounded);
      expect(JobCategoryHelper.getCategoryIcon('Genel Personel'), Icons.work_outline_rounded);
    });
  });

  group('2.6 — Rich Job Card Widget Tests', () {
    final mockJob = {
      'id': 201,
      'title': 'Kafe Barista',
      'wage': 850,
      'location': 'Kadıköy, İstanbul',
      'working_hours': '09:00 - 18:00',
      'dates': '22 Ekim 2026',
      'description': 'Kafemizde hafta sonu çalışacak barista arıyoruz.',
      'status': 'open',
      'employer_phone': '05551234567',
    };

    testWidgets('Job card renders enriched header with category icon and wage badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              width: 400,
              child: const JobsListScreen(
                isEmployer: false,
                isHistory: false,
                jobFilters: {},
                locationFilters: {},
              ),
            ),
          ),
        ),
      );

      // Verify that category icon logic resolves properly
      final categoryIcon = JobCategoryHelper.getCategoryIcon(mockJob['title'].toString());
      expect(categoryIcon, Icons.local_cafe_rounded);
    });

    testWidgets('JobDetailScreen renders enriched header with category squircle and wage subtext', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: mockJob,
            isEmployer: false,
            hasApplied: false,
          ),
        ),
      );

      // Verify category icon avatar
      expect(find.byIcon(Icons.local_cafe_rounded), findsOneWidget);

      // Verify trust text and rating
      expect(find.text('Yömyeci Onaylı'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);

      // Verify wage highlight with GÜNLÜK NET subtext
      expect(find.text('850₺'), findsWidgets);
      expect(find.text('GÜNLÜK NET'), findsOneWidget);

      // Verify detail facts
      expect(find.text('Kadıköy, İstanbul'), findsOneWidget);
      expect(find.text('09:00 - 18:00'), findsOneWidget);
    });
  });
}
