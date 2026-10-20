import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/validators.dart';

void main() {
  group('1.9 — Input Sanitization & XSS Protection Tests', () {
    test('sanitizeText strips dangerous HTML tags and scripts', () {
      const payload1 = "<script>alert('XSS')</script>Merhaba Dünya";
      expect(Validators.sanitizeText(payload1), 'alert(\'XSS\')Merhaba Dünya');

      const payload2 = "<img src='x' onerror='alert(1)'>";
      expect(Validators.sanitizeText(payload2), '');

      const payload3 = "<b>Kalın Yazı</b> ve <iframe src='malicious.com'></iframe>";
      expect(Validators.sanitizeText(payload3), 'Kalın Yazı ve');
    });

    test('sanitizeText removes null bytes and control characters', () {
      const payload = "Temiz\u0000Metin\u0008Test";
      expect(Validators.sanitizeText(payload), 'TemizMetinTest');
    });

    test('sanitizeText trims and applies maxLength properly', () {
      const payload = "   Uzun bir ilan açıklaması buraya geliyor   ";
      expect(Validators.sanitizeText(payload, maxLength: 10), 'Uzun bir i');
    });

    test('containsPotentialXss detects various attack payloads', () {
      expect(Validators.containsPotentialXss("<script>alert(1)</script>"), isTrue);
      expect(Validators.containsPotentialXss("javascript:alert(1)"), isTrue);
      expect(Validators.containsPotentialXss("<img src=x onerror=alert(1)>"), isTrue);
      expect(Validators.containsPotentialXss("<iframe src='evil.com'>"), isTrue);
      expect(Validators.containsPotentialXss("onload=attack()"), isTrue);

      // Safe strings
      expect(Validators.containsPotentialXss("Hafta sonu garson aranıyor"), isFalse);
      expect(Validators.containsPotentialXss("Mado Kızılay Şubesi - Saat: 09:00"), isFalse);
      expect(Validators.containsPotentialXss(""), isFalse);
      expect(Validators.containsPotentialXss(null), isFalse);
    });

    test('isValidName accepts valid Turkish names and rejects injections', () {
      expect(Validators.isValidName('Ahmet Çetin'), isTrue);
      expect(Validators.isValidName('Şeyma Özgül'), isTrue);
      expect(Validators.isValidName('İpek Işık-Demir'), isTrue);
      expect(Validators.isValidName('Ömer Can'), isTrue);

      // Injections and invalid names
      expect(Validators.isValidName("<script>"), isFalse);
      expect(Validators.isValidName("Ahmet123"), isFalse);
      expect(Validators.isValidName("Admin' OR '1'='1"), isFalse);
      expect(Validators.isValidName("A"), isFalse); // too short
      expect(Validators.isValidName("   "), isFalse);
    });

    test('isValidWage validates positive numbers and rejects injection attacks', () {
      expect(Validators.isValidWage('500'), isTrue);
      expect(Validators.isValidWage('750.50'), isTrue);
      expect(Validators.isValidWage('1250,75'), isTrue);

      // Invalid wages
      expect(Validators.isValidWage('0'), isFalse);
      expect(Validators.isValidWage('-100'), isFalse);
      expect(Validators.isValidWage("500; DROP TABLE users;--"), isFalse);
      expect(Validators.isValidWage("abc"), isFalse);
      expect(Validators.isValidWage(""), isFalse);
    });

    test('denyHtmlTagFormatter prevents typing < and > in form fields', () {
      final formatter = Validators.denyHtmlTagFormatter;

      const oldValue = TextEditingValue(text: 'Güvenli');
      const newValue = TextEditingValue(text: 'Güvenli<script>');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'Güvenliscript');
      expect(result.text.contains('<'), isFalse);
      expect(result.text.contains('>'), isFalse);
    });
  });
}
