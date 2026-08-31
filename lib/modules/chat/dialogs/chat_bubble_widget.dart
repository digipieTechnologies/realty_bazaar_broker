// File: lib/modules/chat/dialogs/chat_bubble_widget.dart
// Purpose: Generic Chat bubble widget delegating rendering based on ChatMessageMessageType, separating document attachments into FileMessageWidget and images/videos into MediaGridMessageWidget.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/utils/common_ext.dart';
import '../../../models/models.dart';
import '../widgets/chat_message_focus_menu_widget.dart';
import '../widgets/chat_reply_snippet_widget.dart';
import '../widgets/message_type/file_message_widget.dart';
import '../widgets/message_type/location_message_widget.dart';
import '../widgets/message_type/media_grid_message_widget.dart';
import '../widgets/message_type/text_message_widget.dart';

class ChatBubbleWidget extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool showTimeHeader;
  final VoidCallback? onCopy;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.showTimeHeader = true,
    this.onCopy,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatted = DateFormat('hh:mm a').format(message.createdAt.toLocal());
    final isMarketing = message.senderType == 'marketing' || message.senderType == 'admin';
    final senderLabel = isMe ? 'You' : (isMarketing ? 'Marketing Team' : 'Broker');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            if (showTimeHeader)
              CircleAvatar(
                radius: 15.0,
                backgroundColor: isMarketing
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.secondary.withValues(alpha: 0.12),
                child: Icon(
                  isMarketing ? Icons.support_agent_rounded : Icons.person_rounded,
                  size: 16.0,
                  color: isMarketing ? AppColors.primary : AppColors.secondary,
                ),
              )
            else
              const SizedBox(width: 30.0),
            const SizedBox(width: 8.0),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showTimeHeader) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe) ...[
                        Text(
                          senderLabel,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                      ],
                      Text(
                        timeFormatted,
                        style: AppTextStyles.caption.copyWith(fontSize: 10.0, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3.0),
                ],
                ChatMessageFocusMenuWidget(
                  message: message,
                  isMe: isMe,
                  onCopy: onCopy,
                  onReply: onReply,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320.0),
                    padding:
                        message.medias.isNotEmpty || message.messageType == ChatMessageMessageType.document
                        ? const EdgeInsets.all(4.0)
                        : const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16.0),
                        topRight: const Radius.circular(16.0),
                        bottomLeft: Radius.circular(isMe ? 16.0 : 4.0),
                        bottomRight: Radius.circular(isMe ? 4.0 : 16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.replyMessageId != null || message.replyMessage != null)
                          ChatReplySnippetWidget(replyMessage: message.replyMessage, isMe: isMe),
                        _buildMessageContent(),
                        if (message.isEdited) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            'edited',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontStyle: FontStyle.italic,
                              color: isMe ? Colors.white.withValues(alpha: 0.75) : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    // 1. Multi-media list processing
    if (message.medias.isNotEmpty) {
      final visualMedias = message.medias.where((m) => m.isImage || m.isVideo).toList();
      final documentMedias = message.medias.where((m) => m.isDocument).toList();

      if (documentMedias.isNotEmpty && visualMedias.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...documentMedias.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: FileMessageWidget(
                  mediaUrl: doc.url ?? '',
                  fileName: (doc.url != null && doc.url!.isNotEmpty)
                      ? doc.url!.fileNameFromUrl
                      : message.message,
                  isMe: isMe,
                ),
              ),
            ),
            if (message.message != null &&
                message.message!.trim().isNotEmpty &&
                !documentMedias.any((d) => d.url == message.message))
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                child: TextMessageWidget(text: message.message!, isMe: isMe),
              ),
          ],
        );
      } else if (visualMedias.isNotEmpty && documentMedias.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaGridMessageWidget(medias: visualMedias, caption: null, isMe: isMe),
            const SizedBox(height: 6.0),
            ...documentMedias.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: FileMessageWidget(
                  mediaUrl: doc.url ?? '',
                  fileName: (doc.url != null && doc.url!.isNotEmpty)
                      ? doc.url!.fileNameFromUrl
                      : message.message,
                  isMe: isMe,
                ),
              ),
            ),
            if (message.message != null && message.message!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                child: TextMessageWidget(text: message.message!, isMe: isMe),
              ),
          ],
        );
      }

      return MediaGridMessageWidget(medias: visualMedias, caption: message.message, isMe: isMe);
    }

    // 2. Text or document/location messages
    switch (message.messageType) {
      case ChatMessageMessageType.document:
        final docUrl = message.medias.isNotEmpty
            ? message.medias.first.url
            : (message.message != null &&
                      (message.message!.startsWith('http') || message.message!.isDocumentUrl)
                  ? message.message
                  : null);
        if (docUrl != null && docUrl.isNotEmpty) {
          return FileMessageWidget(mediaUrl: docUrl, fileName: docUrl.fileNameFromUrl, isMe: isMe);
        }
        return TextMessageWidget(text: message.message ?? '', isMe: isMe);

      case ChatMessageMessageType.location:
        return LocationMessageWidget(
          locationText: message.message ?? 'Location',
          latitude: message.latitude,
          longitude: message.longitude,
          locationData: message.locationData,
          isMe: isMe,
        );

      case ChatMessageMessageType.text:
        final textMsg = message.message ?? '';
        if (textMsg.startsWith('http') && textMsg.isDocumentUrl) {
          return FileMessageWidget(mediaUrl: textMsg, fileName: textMsg.fileNameFromUrl, isMe: isMe);
        }
        return TextMessageWidget(text: textMsg, isMe: isMe);
    }
  }
}
