import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/add_job_screen.dart';
import 'package:my_app/job_detail_screen.dart';

void main() {
  final singleWorkerJob = {
    'id': 1,
    'title': 'Konser Organizasyonu Garson',
    'location': 'Ankara, Çankaya, Tunalı Hilmi',
    'working_hours': '17:00 - 23:00',
    'wage': '850.00',
    'description': 'VIP servis ve yemek dahildir.',
    'dates': '18 Ekim 2026',
    'worker_count': 1,
    'accepted_count': 0,
    'status': 'open',
    'employer_phone': '05445073525',
  };

  final multiWorkerJob = {
    'id': 2,
    'title': 'Özel Davet Vale Görevlisi',
    'location': 'Ankara, Yenimahalle, Batıkent',
    'working_hours': '18:00 - 01:00',
    'wage': '1200.00',
    'description': 'Misafir karşılama ve vale hizmeti.',
    'dates': '19 Ekim 2026',
    'worker_count': 3,
    'accepted_count': 1,
    'status': 'open',
    'employer_phone': '05445073525',
  };

  final fullQuotaJob = {
    'id': 3,
    'title': 'Fuar Tanıtım Hostu',
    'location': 'Ankara, Altındağ, ATO Congresium',
    'working_hours': '10:00 - 18:00',
    'wage': '950.00',
    'description': 'Broşür ve stand desteği.',
    'dates': '20 Ekim 2026',
    'worker_count': 2,
    'accepted_count': 2,
    'status': 'open',
    'employer_phone': '05445073525',
  };

  group('3.5 — AddJobScreen Multi-Position Quota Selector Tests', () {
    testWidgets('renders worker count stepper and quick select pills with default 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddJobScreen(),
        ),
      );

      // Kontenjan başlığı ve açıklaması
      expect(find.text('Aranan Çalışan Sayısı (Kontenjan)'), findsOneWidget);
      expect(find.text('Bu ilan için kaç kişiye ihtiyacınız var?'), findsOneWidget);

      // Başlangıç değeri 1
      expect(find.byKey(const Key('worker_count_text')), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Hızlı seçim çipleri
      expect(find.byKey(const Key('worker_count_chip_1')), findsOneWidget);
      expect(find.byKey(const Key('worker_count_chip_2')), findsOneWidget);
      expect(find.byKey(const Key('worker_count_chip_3')), findsOneWidget);
      expect(find.byKey(const Key('worker_count_chip_5')), findsOneWidget);
      expect(find.byKey(const Key('worker_count_chip_10')), findsOneWidget);
    });

    testWidgets('stepper increments and decrements worker count correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddJobScreen(),
        ),
      );

      final addBtn = find.widgetWithIcon(IconButton, Icons.add_rounded);
      final removeBtn = find.widgetWithIcon(IconButton, Icons.remove_rounded);

      await tester.ensureVisible(addBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('worker_count_text')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '1');

      // 1 iken azalt butonu devre dışı olmalı
      final removeWidget = tester.widget<IconButton>(removeBtn);
      expect(removeWidget.onPressed, isNull);

      // Artır butonuna bas: 1 -> 2
      await tester.tap(addBtn);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '2');

      // Bir kez daha bas: 2 -> 3
      await tester.tap(addBtn);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '3');

      // Azalt butonuna bas: 3 -> 2
      await tester.tap(removeBtn);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '2');
    });

    testWidgets('tapping quick select pills updates worker count instantly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddJobScreen(),
        ),
      );

      final chip5 = find.byKey(const Key('worker_count_chip_5'));
      await tester.ensureVisible(chip5);
      await tester.pumpAndSettle();

      // 5 Kişi çipine tıkla
      await tester.tap(chip5);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '5');

      // 10 Kişi çipine tıkla
      final chip10 = find.byKey(const Key('worker_count_chip_10'));
      await tester.ensureVisible(chip10);
      await tester.pumpAndSettle();
      await tester.tap(chip10);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '10');

      // 2 Kişi çipine tıkla
      final chip2 = find.byKey(const Key('worker_count_chip_2'));
      await tester.ensureVisible(chip2);
      await tester.pumpAndSettle();
      await tester.tap(chip2);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '2');
    });

    testWidgets('pre-fills worker count in edit mode when jobToEdit has worker_count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddJobScreen(jobToEdit: multiWorkerJob),
        ),
      );

      expect(tester.widget<Text>(find.byKey(const Key('worker_count_text'))).data, '3');
    });
  });

  group('3.5 — JobDetailScreen Multi-Position Quota Tests', () {
    testWidgets('displays quota details row for multi-position job', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: multiWorkerJob,
            isEmployer: false,
          ),
        ),
      );

      expect(find.text('Kontenjan / Pozisyon'), findsOneWidget);
      expect(find.text('3 Kişi (1/3 Dolu)'), findsOneWidget);
      expect(find.text('Hemen Başvur (1200.00₺)'), findsOneWidget);
    });

    testWidgets('disables apply button when quota is full and indicates full status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(
            job: fullQuotaJob,
            isEmployer: false,
          ),
        ),
      );

      expect(find.text('Kontenjan / Pozisyon'), findsOneWidget);
      expect(find.text('2 Kişi (Kontenjan Doldu)'), findsOneWidget);

      // Başvuru butonu devre dışı ve Kontenjan Doldu metni içeriyor
      expect(find.text('Kontenjan Doldu (2/2)'), findsOneWidget);
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNull);
    });
  });
}
