// File: lib/modules/chat/widgets/chat_message_focus_menu_widget.dart
// Purpose: Separate reusable focus menu popup widget handling long-press (mobile) and right-click (desktop/web) using AppPopupMenu helper.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_colors.dart';
import '../../../models/chat_enums.dart';
import '../../../models/chat_message_model.dart';
import '../../../widgets/buttons/app_popup_menu_button.dart';
import '../../../widgets/toast/app_toast.dart';

class ChatMessageFocusMenuWidget extends StatelessWidget {
  final Widget child;
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onCopy;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatMessageFocusMenuWidget({
    super.key,
    required this.child,
    required this.message,
    required this.isMe,
    this.onCopy,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  void _showFocusMenu(BuildContext context, Offset globalPosition) async {
    final isTextOnlyMessage =
        message.messageType == ChatMessageMessageType.text &&
        message.medias.isEmpty &&
        message.locationData == null;

    final String? action = await AppPopupMenu.show<String>(
      context: context,
      positionOffset: globalPosition,
      items: [
        // 1. Copy Option
        if (message.message != null && message.message!.isNotEmpty)
          const AppPopupMenuItem<String>(
            value: 'copy',
            label: 'Copy',
            iconData: Icons.copy_rounded,
            iconColor: AppColors.textPrimary,
          ),

        // 2. Reply Option
        const AppPopupMenuItem<String>(
          value: 'reply',
          label: 'Reply',
          iconData: Icons.reply_rounded,
          iconColor: AppColors.textPrimary,
        ),

        // 3. Edit Option (only for text-only messages sent by current user)
        if (isMe && !message.isDeleted && isTextOnlyMessage)
          const AppPopupMenuItem<String>(
            value: 'edit',
            label: 'Edit',
            iconData: Icons.edit_outlined,
            iconColor: AppColors.textPrimary,
          ),

        // 4. Delete Option (only for messages sent by current user)
        if (isMe && !message.isDeleted)
          const AppPopupMenuItem<String>(
            value: 'delete',
            label: 'Delete',
            iconData: Icons.delete_outline_rounded,
            iconColor: AppColors.error,
            textColor: AppColors.error,
          ),
      ],
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case 'copy':
        if (message.message != null) {
          await Clipboard.setData(ClipboardData(text: message.message!));
          AppToast.showSuccess('Copied', 'Message copied to clipboard.');
          onCopy?.call();
        }
        break;
      case 'reply':
        onReply?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _showFocusMenu(context, details.globalPosition);
      },
      onSecondaryTapDown: (details) {
        _showFocusMenu(context, details.globalPosition);
      },
      child: child,
    );
  }
}
