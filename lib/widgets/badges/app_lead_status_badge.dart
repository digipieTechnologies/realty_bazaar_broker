// File: lib/widgets/badges/app_lead_status_badge.dart
// Purpose: Interactive, theme-aware badge for displaying and quickly changing lead status (active, inactive, junk) in the broker app.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/lead_status_enum.dart';

class AppLeadStatusBadge extends StatelessWidget {
  final LeadStatus status;
  final ValueChanged<LeadStatus>? onStatusChanged;
  final bool isInteractive;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final bool isSolid;

  const AppLeadStatusBadge({
    super.key,
    required this.status,
    this.onStatusChanged,
    this.isInteractive = true,
    this.iconSize = 13.0,
    this.padding,
    this.isLoading = false,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    final canInteract = isInteractive && onStatusChanged != null && !isLoading;
    final color = status.color;
    final bgColor = status.backgroundColor(context, isSolid);
    final borderColor = status.borderColor(context, isSolid);

    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: canInteract ? 8.0 : 10.0, vertical: 4.5);

    final badgeContent = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: color),
            ),
          ] else ...[
            Icon(status.icon, size: iconSize, color: isSolid ? Colors.white : color),
          ],
          const SizedBox(width: 5.0),
          Text(
            status.label(context),
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: isSolid ? Colors.white : color,
              letterSpacing: 0.2,
            ),
          ),
          if (canInteract) ...[
            const SizedBox(width: 3.0),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16.0,
              color: isSolid ? Colors.white : color.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );

    if (!canInteract) {
      return badgeContent;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<LeadStatus>(
        tooltip: context.tr('leads_status_change_title'),
        offset: const Offset(0, 32),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        onSelected: (newStatus) {
          if (newStatus != status) {
            onStatusChanged!(newStatus);
          }
        },
        itemBuilder: (context) => LeadStatus.values.map((s) {
          final isCurrent = s == status;
          return PopupMenuItem<LeadStatus>(
            value: s,
            height: 38,
            child: Row(
              children: [
                Icon(s.icon, size: 16, color: s.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.label(context),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? s.color : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isCurrent) Icon(Icons.check, size: 16, color: s.color),
              ],
            ),
          );
        }).toList(),
        child: badgeContent,
      ),
    );
  }
}
