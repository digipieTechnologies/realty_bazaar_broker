// File: lib/modules/chat/widgets/chat_reply_snippet_widget.dart
// Purpose: Standalone reusable widget for rendering inline reply snippets inside chat bubbles.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../models/chat_enums.dart';
import '../../../models/chat_message_model.dart';

class ChatReplySnippetWidget extends StatelessWidget {
  final ChatMessageModel? replyMessage;
  final bool isMe;

  const ChatReplySnippetWidget({
    super.key,
    required this.replyMessage,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final parent = replyMessage;
    final parentSenderIsMarketing = parent?.senderType == 'marketing' || parent?.senderType == 'admin';
    final parentSenderLabel = parent == null
        ? 'Message'
        : (parentSenderIsMarketing ? 'Marketing Team' : 'Broker');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.0),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : AppColors.primary,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parentSenderLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 2.0),
          _buildReplyContentWidget(parent),
        ],
      ),
    );
  }

  Widget _buildReplyContentWidget(ChatMessageModel? parent) {
    final textStyle = TextStyle(
      fontSize: 11.5,
      color: isMe ? Colors.white70 : AppColors.textSecondary,
    );
    final iconColor = isMe ? Colors.white70 : AppColors.textSecondary;

    if (parent == null) {
      return Text('Message', style: textStyle);
    }

    // 1. Location Message
    if (parent.messageType == ChatMessageMessageType.location || parent.locationData != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 14.0, color: iconColor),
          const SizedBox(width: 4.0),
          Text('Location', style: textStyle),
        ],
      );
    }

    // 2. Media / Document Messages
    if (parent.medias.isNotEmpty) {
      final medias = parent.medias;
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
    if (parent.messageType == ChatMessageMessageType.document) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded, size: 14.0, color: iconColor),
          const SizedBox(width: 4.0),
          Flexible(
            child: Text(
              parent.message != null && parent.message!.isNotEmpty
                  ? parent.message!
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
      parent.message ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );
  }
}
