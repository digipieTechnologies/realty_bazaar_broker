import 'package:flutter_test/flutter_test.dart';
import 'package:the_realty_bazaar/core/extensions/currency_extensions.dart';

void main() {
  group('CurrencyExtensions', () {
    test('formats crores correctly in compact currency', () {
      expect(73315000.toCompactCurrency(), equals('₹ 7.33 Cr'));
      expect(10000000.toCompactCurrency(), equals('₹ 1 Cr'));
    });

    test('formats lakhs correctly in compact currency', () {
      expect(1550000.toCompactCurrency(), equals('₹ 15.50 Lakh'));
      expect(500000.toCompactCurrency(), equals('₹ 5 Lakh'));
    });

    test('formats thousands and smaller amounts', () {
      expect(45000.toCompactCurrency(), equals('₹ 45,000'));
      expect(999.toCompactCurrency(), equals('₹ 999'));
    });

    test('formats full Indian notation correctly', () {
      expect(73315000.toFullIndianCurrency(), equals('₹ 7,33,15,000'));
      expect(1550000.toFullIndianCurrency(), equals('₹ 15,50,000'));
      expect(45000.toFullIndianCurrency(), equals('₹ 45,000'));
      expect(73315000.toIndianNumber(), equals('7,33,15,000'));
    });

    test('handles decimals and nullable values', () {
      expect(73315000.toFullIndianCurrency(includeDecimals: true), equals('₹ 7,33,15,000.00'));
      const num? nullNum = null;
      expect(nullNum.toCompactCurrency(), equals('-'));
      expect(nullNum.toFullIndianCurrency(), equals('-'));
    });
  });
}
