import 'package:flutter/services.dart';

/// Telefon numarası formatlayıcı: 123 456 78 90 (3 - 3 - 2 - 2) veya 0123 456 78 90 (4 - 3 - 2 - 2)
/// Kullanıcı ister 0 ile (05XX XXX XX XX), ister 0 olmadan (5XX XXX XX XX) yazabilsin.
class PhoneInputFormatter extends TextInputFormatter {
  /// Ham metni telefon formatına dönüştürür.
  static String format(String raw) {
    String digits = clean(raw);
    if (digits.isEmpty) return '';

    final hasLeadingZero = digits.startsWith('0');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (hasLeadingZero) {
        // 0 ile başlayan format: 05XX XXX XX XX (boşluklar: 4, 7, 9)
        if (i == 4 || i == 7 || i == 9) {
          buffer.write(' ');
        }
      } else {
        // 0 olmadan başlayan format: 5XX XXX XX XX (boşluklar: 3, 6, 8)
        if (i == 3 || i == 6 || i == 8) {
          buffer.write(' ');
        }
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Sadece temiz rakamları döndürür (varsa +90 veya 90 ayıklanır).
  static String clean(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // +90 veya 90 ile başlıyorsa ve 12 haneliyse baştaki 90'ı kaldırıp standart 0 ekle
    if (digits.startsWith('90') && digits.length >= 12) {
      digits = '0${digits.substring(2)}';
    }

    // 0 ile başlıyorsa en fazla 11 hane, 0 ile başlamıyorsa en fazla 10 hane
    if (digits.startsWith('0')) {
      if (digits.length > 11) {
        digits = digits.substring(0, 11);
      }
    } else {
      if (digits.length > 10) {
        digits = digits.substring(0, 10);
      }
    }

    return digits;
  }

  /// Veritabanı ve API ile uyumlu 11 haneli formata ('0' + 10 hane) dönüştürür.
  static String toDbFormat(String raw) {
    final digits = clean(raw);
    if (digits.length == 10 && !digits.startsWith('0')) {
      return '0$digits';
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      return digits;
    }
    return digits;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    int selectionIndex = newValue.selection.end;

    // 1. Silme işlemi (Backspace) kontrolü
    if (newValue.text.length < oldValue.text.length) {
      int oldEnd = oldValue.selection.end;
      // Eğer kullanıcı tam boşluktan sonra silme tuşuna bastıysa, o boşluktan önceki rakamı da sil
      if (oldEnd > 0 && oldEnd <= oldValue.text.length) {
        if (oldValue.text[oldEnd - 1] == ' ') {
          int targetDigitIndex = oldEnd - 2;
          if (targetDigitIndex >= 0) {
            text = oldValue.text.substring(0, targetDigitIndex) +
                oldValue.text.substring(oldEnd);
            selectionIndex = targetDigitIndex;
          }
        }
      }
    }

    // 2. İmleçten önceki geçerli rakam sayısını hesapla
    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionIndex && i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        digitsBeforeCursor++;
      }
    }

    // 3. Formatla
    final formatted = format(text);

    // 4. Yeni imleç konumunu bul
    int newOffset = 0;
    int matchedDigits = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        matchedDigits++;
      }
      if (matchedDigits == digitsBeforeCursor) {
        newOffset = i + 1;
        break;
      }
    }

    if (digitsBeforeCursor == 0) {
      newOffset = 0;
    }

    if (newOffset > formatted.length) {
      newOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
