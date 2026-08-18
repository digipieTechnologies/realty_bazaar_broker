// File: lib/modules/chat/widgets/chat_edit_preview_widget.dart
// Purpose: Separate reusable widget displaying edit message preview strip above input bar with cancel button.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../models/chat_message_model.dart';

class ChatEditPreviewWidget extends StatelessWidget {
  final ChatMessageModel editingMessage;
  final VoidCallback onCancelEdit;

  const ChatEditPreviewWidget({
    super.key,
    required this.editingMessage,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.0),
        border: const Border(
          left: BorderSide(color: AppColors.secondary, width: 3.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, size: 18.0, color: AppColors.secondary),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editing message',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  editingMessage.message ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded, size: 18.0, color: AppColors.textMuted),
            onPressed: onCancelEdit,
          ),
        ],
      ),
    );
  }
}
