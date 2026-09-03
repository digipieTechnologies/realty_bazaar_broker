// File: lib/models/lead_status_enum.dart
// Purpose: Enumeration representing lead lifecycle status (pending, active, inactive, converted, noResponse, junk).

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../core/localization/app_localizations.dart';

enum LeadStatus {
  pending,
  active,
  inactive,
  converted,
  noResponse,
  junk;

  String get apiValue {
    switch (this) {
      case LeadStatus.pending:
        return 'pending';
      case LeadStatus.active:
        return 'active';
      case LeadStatus.inactive:
        return 'inactive';
      case LeadStatus.converted:
        return 'converted';
      case LeadStatus.noResponse:
        return 'no_response';
      case LeadStatus.junk:
        return 'junk';
    }
  }

  String label(BuildContext context) {
    switch (this) {
      case LeadStatus.pending:
        return context.tr('leads_status_pending');
      case LeadStatus.active:
        return context.tr('leads_status_active');
      case LeadStatus.inactive:
        return context.tr('leads_status_inactive');
      case LeadStatus.converted:
        return context.tr('leads_status_converted');
      case LeadStatus.noResponse:
        return context.tr('leads_status_no_response');
      case LeadStatus.junk:
        return context.tr('leads_status_junk');
    }
  }

  IconData get icon {
    switch (this) {
      case LeadStatus.pending:
        return Icons.schedule_rounded;
      case LeadStatus.active:
        return Icons.check_circle_rounded;
      case LeadStatus.inactive:
        return Icons.pause_circle_filled_rounded;
      case LeadStatus.converted:
        return Icons.verified_rounded;
      case LeadStatus.noResponse:
        return Icons.phone_missed_rounded;
      case LeadStatus.junk:
        return Icons.delete_sweep_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LeadStatus.pending:
        return const Color(0xFF2563EB); // Royal Blue
      case LeadStatus.active:
        return AppColors.success; // Emerald Green
      case LeadStatus.inactive:
        return AppColors.warning; // Amber Orange
      case LeadStatus.converted:
        return const Color(0xFF7C3AED); // Royal Violet
      case LeadStatus.noResponse:
        return const Color(0xFF64748B); // Slate Grey
      case LeadStatus.junk:
        return AppColors.error; // Red
    }
  }

  Color backgroundColor(BuildContext context, [bool isSolid = false]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSolid) {
      return color;
    }
    return color.withValues(alpha: isDark ? 0.18 : 0.10);
  }

  Color borderColor(BuildContext context, [bool isSolid = false]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSolid) {
      return color;
    }
    return color.withValues(alpha: isDark ? 0.35 : 0.25);
  }

  static LeadStatus fromString(String? value) {
    if (value == null) return LeadStatus.pending;
    switch (value.toLowerCase().replaceAll('_', '').replaceAll('-', '').trim()) {
      case 'pending':
        return LeadStatus.pending;
      case 'active':
        return LeadStatus.active;
      case 'inactive':
        return LeadStatus.inactive;
      case 'converted':
        return LeadStatus.converted;
      case 'noresponse':
        return LeadStatus.noResponse;
      case 'junk':
        return LeadStatus.junk;
      default:
        return LeadStatus.pending;
    }
  }
}
