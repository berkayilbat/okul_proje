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
        '[a-zA-Z\\u011F\\u011E\\u00FC\\u00DC\\u015F\\u015E\\u0131\\u0130\\u00F6\\u00D6\\u00E7\\u00C7]',
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
}
