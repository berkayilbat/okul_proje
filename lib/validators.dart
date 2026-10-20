import 'package:flutter/services.dart';

class Validators {
  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // 10 haneli format: örn. 5445073525 veya 1234567890 (0 ile başlamayan)
    if (digits.length == 10 && !digits.startsWith('0')) {
      return int.tryParse(digits) != null;
    }

    // 11 haneli format: örn. 05445073525 (0 ile başlayan)
    if (digits.length == 11 && digits.startsWith('0')) {
      return int.tryParse(digits) != null;
    }

    return false;
  }

  static bool isValidPassword(String password) {
    if (password.length < 8 || password.length > 20) return false;

    bool hasLetter = password.contains(
      RegExp(
        r'[a-zA-Z\u011F\u011E\u00FC\u00DC\u015F\u015E\u0131\u0130\u00F6\u00D6\u00E7\u00C7]',
      ),
    );
    bool hasSpecial = password.contains(
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-\=\[\]\{\};:"\\|,.<>\/?]'),
    );

    return hasLetter && hasSpecial;
  }

  /// 11 haneli T.C. Kimlik Numarası doğrulama algoritması.
  static bool isValidIdNumber(String idValue) {
    if (idValue.length != 11) return false;
    if (idValue.startsWith('0')) return false;
    if (int.tryParse(idValue) == null) return false;

    List<int> digits = idValue.split('').map((e) => int.parse(e)).toList();

    int sumOdd = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
    int sumEven = digits[1] + digits[3] + digits[5] + digits[7];

    int calculatedDigit10 = ((sumOdd * 7) - sumEven) % 10;

    if (digits[9] != calculatedDigit10) return false;

    int sumFirst10 = 0;
    for (int i = 0; i < 10; i++) {
      sumFirst10 += digits[i];
    }

    int calculatedDigit11 = sumFirst10 % 10;

    if (digits[10] != calculatedDigit11) return false;

    return true;
  }

  /// T.C. Kimlik Numarası için alias.
  static bool isValidTcNumber(String tcValue) => isValidIdNumber(tcValue);

  /// 10 haneli Vergi Kimlik Numarası (VKN) doğrulama algoritması.
  static bool isValidTaxNumber(String taxValue) {
    final trimmed = taxValue.trim();
    if (trimmed.length != 10) return false;
    if (int.tryParse(trimmed) == null) return false;

    final digits = trimmed.split('').map((e) => int.parse(e)).toList();

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      // 1-based pozisyon (sağdan sola): 9 - i
      final int weight = 9 - i;
      final int v1 = (digits[i] + weight) % 10;
      if (v1 != 0) {
        int v2 = (v1 * (1 << weight)) % 9;
        if (v2 == 0) v2 = 9;
        sum += v2;
      }
    }

    final int calculatedLastDigit = (10 - (sum % 10)) % 10;
    return digits[9] == calculatedLastDigit;
  }

  /// [isValidTaxNumber] için alias (VKN).
  static bool isValidVkn(String vkn) => isValidTaxNumber(vkn);

  // ==================== 1.9 SANITIZATION & SECURITY HELPERS ====================

  /// Metin girdilerini XSS, HTML etiketleri ve null byte'lardan temizler.
  static String sanitizeText(String? input, {int? maxLength}) {
    if (input == null) return '';
    // Null byte ve görünmeyen kontrol karakterlerini kaldır
    String sanitized = input.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');
    // HTML etiketlerini ayıkla
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    // Çevreleyen boşlukları kırp
    sanitized = sanitized.trim();
    // Maksimum uzunluk sınırı
    if (maxLength != null && maxLength > 0 && sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    return sanitized;
  }

  /// Potansiyel XSS veya script enjeksiyon deseni içerip içermediğini kontrol eder.
  static bool containsPotentialXss(String? input) {
    if (input == null || input.isEmpty) return false;
    final lower = input.toLowerCase();
    final dangerousPatterns = [
      '<script',
      '</script',
      'javascript:',
      'onerror=',
      'onload=',
      'onclick=',
      'onmouseover=',
      '<iframe',
      '<object',
      '<embed',
      'expression(',
      'document.cookie',
      'window.location',
    ];
    for (final pattern in dangerousPatterns) {
      if (lower.contains(pattern)) return true;
    }
    return false;
  }

  /// Ad / Soyad alanı doğrulama (sadece harf, boşluk ve tire).
  static bool isValidName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 50) return false;
    // Türkçe ve Latin harfleri, boşluk ve tireye izin verilir
    return RegExp(
      r'^[a-zA-Z\u011F\u011E\u00FC\u00DC\u015F\u015E\u0131\u0130\u00F6\u00D6\u00E7\u00C7\s\-]+$',
    ).hasMatch(trimmed);
  }

  /// Pozitif yevmiye / ücret doğrulama.
  static bool isValidWage(String wage) {
    final cleaned = wage.replaceAll(',', '.').trim();
    final value = double.tryParse(cleaned);
    return value != null && value > 0 && value <= 100000;
  }

  /// Zararlı HTML etiketlerinin yazılmasını engelleyen güvenli metin formatter'ı.
  static TextInputFormatter get denyHtmlTagFormatter =>
      FilteringTextInputFormatter.deny(RegExp(r'[<>]'));

  /// Sadece isim karakterlerine izin veren formatter.
  static TextInputFormatter get nameInputFormatter =>
      FilteringTextInputFormatter.allow(
        RegExp(
          r'[a-zA-Z\u011F\u011E\u00FC\u00DC\u015F\u015E\u0131\u0130\u00F6\u00D6\u00E7\u00C7\s\-]',
        ),
      );

  /// Sadece para/ücret girişine izin veren formatter (ondalıklı veya tamsayı).
  static TextInputFormatter get wageInputFormatter =>
      FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'));
}
