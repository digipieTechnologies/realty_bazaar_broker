// File: lib/util/app_date_utils.dart
// Purpose: Centralized type-safe date formatting helper using intl DateFormat across all features.

import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  /// Standard date format: '26, Jan 2026' (Format pattern: d, MMM yyyy)
  static String formatFullDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('d, MMM yyyy').format(dateTime);
  }

  /// Date format with time: '26, Jan 2026 at 14:30' (Format pattern: d, MMM yyyy 'at' HH:mm)
  static String formatDateWithTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat("d, MMM yyyy 'at' HH:mm").format(dateTime);
  }

  /// Formats ISO String or DateTime into standard '26, Jan 2026' format
  static String formatDate(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) return formatFullDate(date);
    if (date is String) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return formatFullDate(parsed);
    }
    return date.toString();
  }

  /// Formats ISO String or DateTime into '26, Jan 2026 at 14:30'
  static String formatDateTime(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) return formatDateWithTime(date);
    if (date is String) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return formatDateWithTime(parsed);
    }
    return date.toString();
  }
}
