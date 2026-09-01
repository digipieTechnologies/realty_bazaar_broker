// File: lib/util/currency_formatter.dart
// Purpose: Centralized helper class and extension for formatting Indian currency (e.g. ₹13,999).

import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormatter = NumberFormat('#,##,###', 'en_IN');

  /// Formats amount to Indian currency string: ₹14,999
  static String format(num? amount, {bool showSymbol = true}) {
    if (amount == null || amount <= 0) {
      return showSymbol ? '₹0' : '0';
    }
    final formatted = _inrFormatter.format(amount.toInt());
    return showSymbol ? '₹$formatted' : formatted;
  }
}

extension NumCurrencyX on num? {
  /// Converts number to Indian currency format: 14999.toCurrency() -> "₹14,999"
  String toCurrency({bool showSymbol = true}) {
    return CurrencyFormatter.format(this, showSymbol: showSymbol);
  }
}
