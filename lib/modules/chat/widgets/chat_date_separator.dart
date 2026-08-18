// File: lib/modules/chat/widgets/chat_date_separator.dart
// Purpose: Centered pill date separator widget with short fading gradient lines on both sides.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/app_colors.dart';

class ChatDateSeparator extends StatelessWidget {
  final String date;

  const ChatDateSeparator({
    super.key,
    required this.date,
  });

  /// Formats a DateTime into Today, Yesterday, "dd, MMMM", or "dd, MMMM yyyy".
  static String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    if (msgDay == today) {
      return 'Today';
    } else if (msgDay == yesterday) {
      return 'Yesterday';
    } else if (now.year == date.year) {
      return DateFormat('dd, MMMM').format(date);
    } else {
      return DateFormat('dd, MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = AppColors.border.withValues(alpha: 0.8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left short fading gradient line
          Container(
            width: 48.0,
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, lineColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          const SizedBox(width: 8.0),

          // Date Pill Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.5),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 8.0),

          // Right short fading gradient line
          Container(
            width: 48.0,
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lineColor, Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
