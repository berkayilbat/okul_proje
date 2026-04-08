class Validators {
  static bool isValidPhone(String phone) {
    if (phone.length != 11) return false;
    if (!phone.startsWith('0')) return false;

    // Tüm karakterlerin rakam olduğunu doğrula
    if (int.tryParse(phone) == null) return false;

    return true;
  }

  static bool isValidPassword(String password) {
    if (password.length < 8 || password.length > 20) return false;

    bool hasLetter = password.contains(
      RegExp(
        '[a-zA-Z\\u011F\\u011E\\u00FC\\u00DC\\u015F\\u015E\\u0131\\u0130\\u00F6\\u00D6\\u00E7\\u00C7]',
      ),
    );
    bool hasSpecial = password.contains(
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-\=\[\]\{\};:"\\|,.<>\/?]'),
    );

    return hasLetter && hasSpecial;
  }

  static bool isValidIdNumber(String idValue) {
    // TC Kimlik ve istenen Vergi Kimlik kuralları aynı olacak şekilde
    // 11 haneli olmalı, 0 ile başlayamaz
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
}
