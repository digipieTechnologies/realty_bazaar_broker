// File: lib/modules/chat/widgets/chat_header_widget.dart
// Purpose: Standalone reusable chat header widget displaying title, subtitle/property, status badge, and close button.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class ChatHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Widget? leading;
  final List<Widget>? actions;

  const ChatHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Row(
        children: [
          leading ??
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20.0),
              ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(fontSize: 15.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(fontSize: 11.5, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              onPressed: onClose,
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}
