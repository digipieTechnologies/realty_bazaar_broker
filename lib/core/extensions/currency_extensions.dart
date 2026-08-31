// File: lib/core/extensions/currency_extensions.dart
// Purpose: Extension methods on num/num? for consistent, reusable currency and Indian number formatting.

import 'package:intl/intl.dart';

extension CurrencyExtensions on num {
  /// Formats amount into compact Indian currency representation (e.g. ₹ 7.33 Cr, ₹ 15.50 Lakh, ₹ 5,000).
  ///
  /// [symbol]: Currency symbol prefix (default: '₹ ').
  /// [decimalDigits]: Number of decimal places to keep for Cr/Lakh (default: 2).
  String toCompactCurrency({String symbol = '₹ ', int decimalDigits = 2, bool spaceBetweenSymbol = false}) {
    final double amount = toDouble();
    final String cleanSymbol = symbol.trim().isEmpty
        ? ''
        : spaceBetweenSymbol
        ? '${symbol.trim()} '
        : symbol;

    if (amount.abs() >= 10000000) {
      final formatted = (amount / 10000000).toStringAsFixed(decimalDigits);
      // Remove trailing zero decimals if needed, e.g. 7.00 -> 7
      final cleaned = formatted.replaceAll(RegExp(r'\.0+$'), '');
      return '$cleanSymbol$cleaned Cr';
    } else if (amount.abs() >= 100000) {
      final formatted = (amount / 100000).toStringAsFixed(decimalDigits);
      final cleaned = formatted.replaceAll(RegExp(r'\.0+$'), '');
      return '$cleanSymbol$cleaned Lakh';
    } else if (amount.abs() >= 1000) {
      final formatter = NumberFormat('#,##,###', 'en_IN');
      return '$cleanSymbol${formatter.format(amount.toInt())}';
    } else {
      return '$cleanSymbol${amount.toStringAsFixed(0)}';
    }
  }

  /// Formats exact amount into full Indian number system comma-separated notation.
  /// Example: 73315000 -> "₹ 7,33,15,000" or "7,33,15,000"
  ///
  /// [symbol]: Currency symbol prefix (default: '₹ '). Set to '' if only formatted numbers are needed.
  /// [includeDecimals]: Whether to show 2 decimal places (e.g. ₹ 7,33,15,000.00). Default is false.
  String toFullIndianCurrency({
    String symbol = '₹ ',
    bool includeDecimals = false,
    bool spaceBetweenSymbol = false,
  }) {
    final double amount = toDouble();
    final String pattern = includeDecimals ? '#,##,##0.00' : '#,##,##0';
    final NumberFormat formatter = NumberFormat(pattern, 'en_IN');
    final String formattedNumber = formatter.format(includeDecimals ? amount : amount.toInt());

    final String cleanSymbol = symbol.trim().isEmpty
        ? ''
        : spaceBetweenSymbol
        ? '${symbol.trim()} '
        : symbol;

    return '$cleanSymbol$formattedNumber';
  }

  /// Formats number into raw Indian comma notation without currency symbol (e.g. 7,33,15,000).
  String toIndianNumber({bool includeDecimals = false}) {
    return toFullIndianCurrency(symbol: '', includeDecimals: includeDecimals);
  }
}

extension NullableCurrencyExtensions on num? {
  /// Safe compact currency formatting for nullable numbers.
  String toCompactCurrency({
    String symbol = '₹ ',
    int decimalDigits = 2,
    bool spaceBetweenSymbol = false,
    String defaultFallback = '-',
  }) {
    if (this == null) return defaultFallback;
    return this!.toCompactCurrency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      spaceBetweenSymbol: spaceBetweenSymbol,
    );
  }

  /// Safe full Indian currency formatting for nullable numbers.
  String toFullIndianCurrency({
    String symbol = '₹ ',
    bool includeDecimals = false,
    bool spaceBetweenSymbol = false,
    String defaultFallback = '-',
  }) {
    if (this == null) return defaultFallback;
    return this!.toFullIndianCurrency(
      symbol: symbol,
      includeDecimals: includeDecimals,
      spaceBetweenSymbol: spaceBetweenSymbol,
    );
  }
}
