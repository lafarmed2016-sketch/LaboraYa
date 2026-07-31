import 'package:flutter_test/flutter_test.dart';
import 'package:laboraya_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('format returns symbol and integer for whole numbers', () {
      expect(CurrencyFormatter.format(100), 'S/ 100');
      expect(CurrencyFormatter.format(250), 'S/ 250');
    });

    test('format returns decimal for non-whole', () {
      expect(CurrencyFormatter.format(99.50), 'S/ 99.50');
    });

    test('format returns A convenir for null', () {
      expect(CurrencyFormatter.format(null), 'A convenir');
    });

    test('formatRange shows range', () {
      expect(CurrencyFormatter.formatRange(100, 200), 'S/ 100 - 200');
    });

    test('formatRange shows single value when min equals max', () {
      expect(CurrencyFormatter.formatRange(150, 150), 'S/ 150');
    });

    test('formatRange shows A convenir when both null', () {
      expect(CurrencyFormatter.formatRange(null, null), 'A convenir');
    });
  });
}
