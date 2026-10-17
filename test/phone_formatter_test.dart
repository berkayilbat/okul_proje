import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/phone_input_formatter.dart';
import 'package:my_app/validators.dart';

void main() {
  group('PhoneInputFormatter Unit Tests', () {
    test('formats 10 digits as 123 456 78 90 (without 0)', () {
      expect(PhoneInputFormatter.format('1234567890'), '123 456 78 90');
      expect(PhoneInputFormatter.format('5445073525'), '544 507 35 25');
    });

    test('formats 11 digits with leading 0 as 0544 507 35 25', () {
      expect(PhoneInputFormatter.format('05445073525'), '0544 507 35 25');
      expect(PhoneInputFormatter.format('01234567890'), '0123 456 78 90');
    });

    test('allows typing single 0 at start', () {
      expect(PhoneInputFormatter.format('0'), '0');
      expect(PhoneInputFormatter.format('05'), '05');
      expect(PhoneInputFormatter.format('054'), '054');
      expect(PhoneInputFormatter.format('0544'), '0544');
      expect(PhoneInputFormatter.format('05445'), '0544 5');
      expect(PhoneInputFormatter.format('0544507'), '0544 507');
      expect(PhoneInputFormatter.format('054450735'), '0544 507 35');
      expect(PhoneInputFormatter.format('05445073525'), '0544 507 35 25');
    });

    test('handles partial numbers gracefully without 0', () {
      expect(PhoneInputFormatter.format('5'), '5');
      expect(PhoneInputFormatter.format('54'), '54');
      expect(PhoneInputFormatter.format('544'), '544');
      expect(PhoneInputFormatter.format('5445'), '544 5');
      expect(PhoneInputFormatter.format('54450'), '544 50');
      expect(PhoneInputFormatter.format('544507'), '544 507');
      expect(PhoneInputFormatter.format('5445073'), '544 507 3');
      expect(PhoneInputFormatter.format('54450735'), '544 507 35');
      expect(PhoneInputFormatter.format('544507352'), '544 507 35 2');
      expect(PhoneInputFormatter.format('5445073525'), '544 507 35 25');
    });

    test('truncates numbers longer than max allowed', () {
      expect(PhoneInputFormatter.format('5445073525999'), '544 507 35 25');
      expect(PhoneInputFormatter.format('05445073525999'), '0544 507 35 25');
    });

    test('handles +90 country prefix properly', () {
      expect(PhoneInputFormatter.format('+905445073525'), '0544 507 35 25');
    });

    test('toDbFormat produces 11-digit leading 0 format from both inputs', () {
      expect(PhoneInputFormatter.toDbFormat('544 507 35 25'), '05445073525');
      expect(PhoneInputFormatter.toDbFormat('0544 507 35 25'), '05445073525');
      expect(PhoneInputFormatter.toDbFormat('05445073525'), '05445073525');
      expect(PhoneInputFormatter.toDbFormat('5445073525'), '05445073525');
    });

    test('interactive formatEditUpdate allows typing 0', () {
      final formatter = PhoneInputFormatter();

      // Typing '0' as first character
      var res = formatter.formatEditUpdate(
        const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0)),
        const TextEditingValue(text: '0', selection: TextSelection.collapsed(offset: 1)),
      );
      expect(res.text, '0');
      expect(res.selection.baseOffset, 1);

      // Typing '5' after '0'
      res = formatter.formatEditUpdate(
        const TextEditingValue(text: '0', selection: TextSelection.collapsed(offset: 1)),
        const TextEditingValue(text: '05', selection: TextSelection.collapsed(offset: 2)),
      );
      expect(res.text, '05');
      expect(res.selection.baseOffset, 2);

      // Typing '05445'
      res = formatter.formatEditUpdate(
        const TextEditingValue(text: '0544', selection: TextSelection.collapsed(offset: 4)),
        const TextEditingValue(text: '05445', selection: TextSelection.collapsed(offset: 5)),
      );
      expect(res.text, '0544 5');
      expect(res.selection.baseOffset, 6); // after the space and digit

      // Backspace when cursor is at '0544 5|'
      res = formatter.formatEditUpdate(
        const TextEditingValue(text: '0544 5', selection: TextSelection.collapsed(offset: 6)),
        const TextEditingValue(text: '0544 ', selection: TextSelection.collapsed(offset: 5)),
      );
      expect(res.text, '0544');
      expect(res.selection.baseOffset, 4);
    });
  });

  group('Validators Phone Tests', () {
    test('validates 10-digit and 11-digit numbers', () {
      expect(Validators.isValidPhone('544 507 35 25'), true);
      expect(Validators.isValidPhone('0544 507 35 25'), true);
      expect(Validators.isValidPhone('5445073525'), true);
      expect(Validators.isValidPhone('05445073525'), true);
      expect(Validators.isValidPhone('123 456 78 90'), true);
      expect(Validators.isValidPhone('0123 456 78 90'), true);
      expect(Validators.isValidPhone('12345'), false);
      expect(Validators.isValidPhone(''), false);
    });
  });
}
