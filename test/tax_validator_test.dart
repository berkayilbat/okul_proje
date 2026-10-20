import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/validators.dart';

void main() {
  group('Validators.isValidTaxNumber (VKN) Tests', () {
    test('validates authentic 10-digit tax numbers correctly', () {
      final validVknList = [
        '0540033975',
        '0540033887',
        '0680066825',
        '1670068615',
        '3950079269',
        '3950079068',
        '4540017830',
        '4540017847',
        '4780040920',
        '4870003769',
        '4540536920',
      ];

      for (final vkn in validVknList) {
        expect(Validators.isValidTaxNumber(vkn), isTrue,
            reason: '$vkn should be valid');
        expect(Validators.isValidVkn(vkn), isTrue,
            reason: '$vkn should be valid via alias');
      }
    });

    test('rejects numbers with invalid checksum', () {
      final invalidChecksums = [
        '0540033974',
        '0540033880',
        '4540536921',
        '1234567891',
        '4780040929',
      ];

      for (final vkn in invalidChecksums) {
        expect(Validators.isValidTaxNumber(vkn), isFalse,
            reason: '$vkn should be rejected for wrong checksum');
      }
    });

    test('rejects invalid length or non-numeric values', () {
      expect(Validators.isValidTaxNumber(''), isFalse);
      expect(Validators.isValidTaxNumber('123456789'), isFalse); // 9 digits
      expect(Validators.isValidTaxNumber('12345678901'), isFalse); // 11 digits
      expect(Validators.isValidTaxNumber('abcdefghij'), isFalse); // letters
      expect(Validators.isValidTaxNumber('054003397a'), isFalse); // alphanumeric
    });
  });
}
