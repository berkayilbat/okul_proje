import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/add_job_screen.dart';
import 'package:my_app/job_detail_screen.dart';

void main() {
  final demoJob = {
    'id': 1,
    'title': 'Konser Organizasyonu Garson',
    'location': 'Ankara, Çankaya, Tunalı Hilmi',
    'working_hours': '17:00 - 23:00',
    'wage': '850.00',
    'description': 'VIP servis ve yemek dahildir.',
    'dates': '18 Ekim 2026',
    'status': 'open',
    'employer_phone': '05445073525',
  };

  group('3.4 — AddJobScreen Edit Mode Tests', () {
    testWidgets('renders Create mode correctly when jobToEdit is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddJobScreen(),
        ),
      );

      expect(find.text('Yeni İlan Oluştur'), findsOneWidget);
      expect(find.text('İlanı Yayınla'), findsOneWidget);
      expect(find.text('İlan Türü Seçin'), findsWidgets);
    });

    testWidgets('renders Edit mode correctly and pre-fills all initial values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddJobScreen(jobToEdit: demoJob),
        ),
      );

      // Başlık ve buton
      expect(find.text('İlanı Düzenle'), findsOneWidget);
      expect(find.text('Değişiklikleri Kaydet'), findsOneWidget);
      expect(find.text('Yeni İlan Oluştur'), findsNothing);

      // Alanlardaki değerler
      expect(find.text('Konser Organizasyonu Garson'), findsWidgets);
      expect(find.text('Ankara, Çankaya'), findsOneWidget);
      expect(find.text('Tunalı Hilmi'), findsOneWidget);
      expect(find.text('17:00 - 23:00'), findsOneWidget);
      expect(find.text('850.00'), findsOneWidget);
      expect(find.text('18 Ekim 2026'), findsOneWidget);
      expect(find.text('VIP servis ve yemek dahildir.'), findsOneWidget);
    });
  });

  group('3.4 — JobDetailScreen Employer Edit Action Tests', () {
    testWidgets('renders edit action in AppBar and bottom bar for employer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: demoJob,
            isEmployer: true,
          ),
        ),
      );

      // İşveren için düzenleme butonları
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.text('İlanı Düzenle'), findsWidgets);
      expect(find.text('Hemen Başvur'), findsNothing);
    });

    testWidgets('does not render edit actions for regular employee', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: demoJob,
            isEmployer: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.text('İlanı Düzenle'), findsNothing);
      expect(find.textContaining('Hemen Başvur'), findsOneWidget);
    });
  });
}
