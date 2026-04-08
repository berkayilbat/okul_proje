import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('App loads login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false, role: 'Employee'));

    // Verify that the login screen is displayed.
    expect(find.text('Giriş Yap'), findsWidgets);
  });
}
