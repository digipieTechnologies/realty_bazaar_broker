// File: lib/widgets/common/currency_text.dart
// Purpose: Reusable Currency Text widget displaying compact currency with an interactive tooltip showing the full exact amount in Indian notation.

import 'package:flutter/material.dart';
import '../../core/extensions/currency_extensions.dart';

/// A widget that displays a compact formatted currency amount with a built-in
/// Tooltip showing the exact full amount in Indian number notation on hover / long-press.
///
/// Example:
/// Shows: "₹ 7.33 Cr"
/// Tooltip: "₹ 7,33,15,000"
class CurrencyText extends StatelessWidget {
  /// The numerical amount (e.g. 73315000)
  final num? amount;

  /// Text style for the displayed compact price
  final TextStyle? style;

  /// Currency symbol prefix (default: '₹ ')
  final String symbol;

  /// Optional prefix string prepended to the visible text
  final String? prefix;

  /// Optional suffix string appended to the visible text (e.g. '/ Month')
  final String? suffix;

  /// Number of decimal digits for compact format (default: 2)
  final int decimalDigits;

  /// Whether to enable tooltip on hover / long press (default: true)
  final bool enableTooltip;

  /// Custom tooltip message to override automatic full amount formatting
  final String? customTooltipMessage;

  /// Text alignment
  final TextAlign? textAlign;

  /// Text overflow behavior
  final TextOverflow? overflow;

  /// Maximum lines of text
  final int? maxLines;

  /// Fallback text when amount is null (default: '-')
  final String fallbackText;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.symbol = '₹ ',
    this.prefix,
    this.suffix,
    this.decimalDigits = 2,
    this.enableTooltip = true,
    this.customTooltipMessage,
    this.textAlign,
    this.overflow,
    this.maxLines = 1,
    this.fallbackText = '-',
  });

  @override
  Widget build(BuildContext context) {
    if (amount == null) {
      return Text(fallbackText, style: style, textAlign: textAlign, overflow: overflow, maxLines: maxLines);
    }

    final compactStr = amount!.toCompactCurrency(symbol: symbol, decimalDigits: decimalDigits);

    final fullIndianStr = customTooltipMessage ?? amount!.toFullIndianCurrency(symbol: symbol);

    final displayText = '${prefix ?? ''}$compactStr${suffix ?? ''}';

    final textWidget = Text(
      displayText,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );

    if (!enableTooltip) {
      return textWidget;
    }

    final tooltipContent = suffix != null && customTooltipMessage == null
        ? '$fullIndianStr$suffix'
        : fullIndianStr;

    return Tooltip(
      message: tooltipContent,
      waitDuration: const Duration(milliseconds: 300),
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      child: textWidget,
    );
  }
}
