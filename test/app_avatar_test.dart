import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/app_avatar.dart';
import 'package:my_app/widgets/avatar_picker_sheet.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/server_config.dart';

void main() {
  group('3.2 — AppAvatar Initials & URL Unit Tests', () {
    test('computeInitials extracts correct uppercase letters', () {
      expect(AppAvatar.computeInitials('Ahmet Yılmaz'), equals('AY'));
      expect(AppAvatar.computeInitials('mehmet can demir'), equals('MD'));
      expect(AppAvatar.computeInitials('Berkay'), equals('B'));
      expect(AppAvatar.computeInitials(''), equals(''));
      expect(AppAvatar.computeInitials(null), equals(''));
      expect(AppAvatar.computeInitials('   '), equals(''));
      expect(AppAvatar.computeInitials(' berat   taştekin '), equals('BT'));
    });

    test('AuthService.getFullImageUrl resolves URLs correctly', () {
      expect(AuthService.getFullImageUrl(null), isNull);
      expect(AuthService.getFullImageUrl(''), isNull);
      expect(AuthService.getFullImageUrl('   '), isNull);

      const fullHttp = 'http://example.com/avatar.jpg';
      expect(AuthService.getFullImageUrl(fullHttp), equals(fullHttp));

      const fullHttps = 'https://cdn.example.com/images/user.png';
      expect(AuthService.getFullImageUrl(fullHttps), equals(fullHttps));

      final expectedBase = ServerConfig.baseUrl;
      expect(
        AuthService.getFullImageUrl('uploads/avatars/avatar123.jpg'),
        equals('$expectedBase/uploads/avatars/avatar123.jpg'),
      );
      expect(
        AuthService.getFullImageUrl('/uploads/avatars/avatar123.jpg'),
        equals('$expectedBase/uploads/avatars/avatar123.jpg'),
      );
    });
  });

  group('3.2 — AppAvatar Widget Tests', () {
    testWidgets('renders initials when imageUrl is null and name is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              radius: 30,
              name: 'Berat Taştekin',
            ),
          ),
        ),
      );

      expect(find.text('BT'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('renders person icon fallback when name and imageUrl are empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              radius: 25,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders edit badge and triggers onEditBadgeTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              radius: 40,
              name: 'Berkay Yılbat',
              showEditBadge: true,
              onEditBadgeTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows loading overlay when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              radius: 40,
              name: 'Caner Yıldız',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('wraps avatar in Hero widget when heroTag is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              radius: 30,
              name: 'Ali Veli',
              heroTag: 'employee-avatar-05551234567',
            ),
          ),
        ),
      );

      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsOneWidget);

      final Hero heroWidget = tester.widget(heroFinder);
      expect(heroWidget.tag, equals('employee-avatar-05551234567'));
    });
  });

  group('3.2 — AvatarPickerSheet Modal Tests', () {
    testWidgets('renders camera and gallery options by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarPickerSheet(hasExistingImage: false),
          ),
        ),
      );

      expect(find.text('Profil Fotoğrafı'), findsOneWidget);
      expect(find.text('Fotoğraf Çek'), findsOneWidget);
      expect(find.text('Galeriden Seç'), findsOneWidget);
      expect(find.text('Fotoğrafı Kaldır'), findsNothing);
    });

    testWidgets('shows delete option when hasExistingImage is true', (tester) async {
      AvatarPickerResult? pickedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    pickedResult = await AvatarPickerSheet.show(
                      context,
                      hasExistingImage: true,
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Fotoğrafı Kaldır'), findsOneWidget);

      await tester.tap(find.text('Fotoğrafı Kaldır'));
      await tester.pumpAndSettle();

      expect(pickedResult, isNotNull);
      expect(pickedResult!.action, equals(AvatarPickerAction.delete));
    });
  });
}
