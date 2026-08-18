import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../models/chat_enums.dart';
import '../../../models/chat_message_model.dart';

class ChatReplyPreviewWidget extends StatelessWidget {
  final ChatMessageModel replyingToMessage;
  final VoidCallback onCancelReply;

  const ChatReplyPreviewWidget({
    super.key,
    required this.replyingToMessage,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.0),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 18.0, color: AppColors.primary),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Replying to message',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2.0),
                _buildReplyContentWidget(replyingToMessage),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded, size: 18.0, color: AppColors.textMuted),
            onPressed: onCancelReply,
          ),
        ],
      ),
    );
  }

  static Widget _buildReplyContentWidget(ChatMessageModel message) {
    const textStyle = TextStyle(
      fontSize: 12.0,
      color: AppColors.textSecondary,
    );
    const iconColor = AppColors.textSecondary;

    // 1. Location Message
    if (message.messageType == ChatMessageMessageType.location || message.locationData != null) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 14.0, color: iconColor),
          SizedBox(width: 4.0),
          Text('Location', style: textStyle),
        ],
      );
    }

    // 2. Media / Document Messages
    if (message.medias.isNotEmpty) {
      final medias = message.medias;
      final count = medias.length;

      bool hasVideo = false;
      bool hasImage = false;
      bool hasDoc = false;

      for (final m in medias) {
        final isVideo = m.isVideo;
        final isDoc = m.type == 'document' || m.type == 'file' || (m.type != 'video' && m.type != 'image' && m.type != 'photo');
        if (isVideo) {
          hasVideo = true;
        } else if (isDoc) {
          hasDoc = true;
        } else {
          hasImage = true;
        }
      }

      IconData iconData;
      String label;

      if (hasDoc || (hasVideo && hasImage)) {
        iconData = Icons.insert_drive_file_rounded;
        label = count == 1 ? '1 Document' : '$count Documents';
      } else if (hasVideo && !hasImage) {
        iconData = Icons.videocam_rounded;
        label = count == 1 ? '1 Video' : '$count Videos';
      } else {
        iconData = Icons.image_rounded;
        label = count == 1 ? '1 Photo' : '$count Photos';
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14.0, color: iconColor),
          const SizedBox(width: 4.0),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      );
    }

    // 3. Document type without media list
    if (message.messageType == ChatMessageMessageType.document) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_rounded, size: 14.0, color: iconColor),
          const SizedBox(width: 4.0),
          Flexible(
            child: Text(
              message.message != null && message.message!.isNotEmpty
                  ? message.message!
                  : '1 Document',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      );
    }

    // 4. Standard Text Message
    return Text(
      message.message ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );
  }
}
