// File: lib/modules/visits/widgets/visit_status_badge.dart
// Purpose: Status pill badge component for site visit statuses with distinct theme colors and icons.

import 'package:flutter/material.dart';

import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class VisitStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const VisitStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String labelKey;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = const Color(0xFFE0F2FE); // sky-100
        fg = const Color(0xFF0369A1); // sky-700
        icon = Icons.check_circle_rounded;
        labelKey = 'status_confirmed';
        break;
      case 'rescheduled':
        bg = const Color(0xFFF3E8FF); // purple-100
        fg = const Color(0xFF7E22CE); // purple-700
        icon = Icons.update_rounded;
        labelKey = 'status_rescheduled';
        break;
      case 'completed':
        bg = const Color(0xFFDCFCE7); // emerald-100
        fg = const Color(0xFF15803D); // emerald-700
        icon = Icons.task_alt_rounded;
        labelKey = 'status_completed';
        break;
      case 'cancelled':
        bg = const Color(0xFFFFE4E6); // rose-100
        fg = const Color(0xFFBE123C); // rose-700
        icon = Icons.cancel_outlined;
        labelKey = 'status_cancelled';
        break;
      case 'no_show':
        bg = const Color(0xFFF1F5F9); // slate-100
        fg = const Color(0xFF475569); // slate-600
        icon = Icons.person_off_outlined;
        labelKey = 'status_no_show';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7); // amber-100
        fg = const Color(0xFFB45309); // amber-700
        icon = Icons.schedule_rounded;
        labelKey = 'status_pending';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 10.0,
        vertical: isCompact ? 3.0 : 5.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12.0 : 14.0, color: fg),
          const SizedBox(width: 4.0),
          Text(
            context.tr(labelKey),
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11.0 : 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
