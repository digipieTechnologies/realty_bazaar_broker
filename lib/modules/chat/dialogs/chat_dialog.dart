// File: lib/modules/chat/dialogs/chat_dialog.dart
// Purpose: Generic responsive Chat Dialog with header (flush edge-to-edge), date headers, reverse ListView scroll pagination, real-time streaming, soft delete, inline edit, and self-contained input bar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/app_colors.dart';
import '../../../models/models.dart';
import '../../../providers/chat/chat_provider.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/shimmer/chat_shimmer_widget.dart';
import '../widgets/chat_date_separator.dart';
import '../widgets/chat_header_widget.dart';
import '../widgets/chat_input_bar_widget.dart';
import '../widgets/say_hello_widget.dart';
import 'chat_bubble_widget.dart';

class ChatDialog extends StatefulWidget {
  final String videoRequestId;
  final String brokerId;
  final String currentUserId;
  final String currentUserType; // 'broker' or 'marketing' / 'admin'
  final String? propertyTitle;
  final String? propertyAddress;
  final String? chatTitle;

  const ChatDialog({
    super.key,
    required this.videoRequestId,
    required this.brokerId,
    required this.currentUserId,
    this.currentUserType = 'broker',
    this.propertyTitle,
    this.propertyAddress,
    this.chatTitle,
  });

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  final ScrollController _scrollController = ScrollController();
  ChatMessageModel? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.initChatRoom(widget.videoRequestId);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 100.0) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.fetchMoreMessages();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleReplyMessage(ChatMessageModel message) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    if (provider.editingMessage != null) {
      provider.setEditingMessage(null);
    }
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _handleEditMessage(ChatMessageModel message, ChatProvider provider) {
    if (_replyingToMessage != null) {
      setState(() {
        _replyingToMessage = null;
      });
    }
    provider.setEditingMessage(message);
  }

  void _handleDeleteMessage(ChatMessageModel message, ChatProvider provider) async {
    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: 'Delete Message?',
      description: 'Are you sure you want to delete this message? This action cannot be undone.',
      type: DialogType.error,
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );

    if (confirmed == true && mounted) {
      await provider.deleteMessage(message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Center(
        child: Container(
          width: screenSize.width > 600 ? 540.0 : screenSize.width * 0.92,
          height: screenSize.height * 0.82,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Consumer<ChatProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: SafeArea(
                  child: Column(
                    children: [
                      // Header Widget (Title: 'Marketing Team' / 'Broker', Subtitle: Property Address / Title)
                      ChatHeaderWidget(
                        title: widget.chatTitle ??
                            (widget.currentUserType == 'broker' ? 'Marketing Team' : 'Broker'),
                        subtitle: widget.propertyTitle ?? widget.propertyAddress,
                        onClose: () => Navigator.of(context).pop(),
                      ),

                      // Chat Messages Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: provider.isLoading
                              ? const ChatShimmerWidget()
                              : provider.errorMessage != null
                                  ? Center(
                                      child: Text(
                                        provider.errorMessage!,
                                        style: const TextStyle(color: AppColors.error),
                                      ),
                                    )
                                  : provider.messages.isEmpty
                                      ? SayHelloWidget(
                                          onSayHello: () {
                                            provider.sendMessage(
                                              senderId: widget.currentUserId,
                                              senderType: widget.currentUserType,
                                              message: 'Hello 👋',
                                            );
                                          },
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          reverse: true,
                                          padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                                          itemCount: provider.messages.length + (provider.isLoadingMore ? 1 : 0),
                                          itemBuilder: (context, index) {
                                            final messages = provider.messages;

                                            if (index == messages.length && provider.isLoadingMore) {
                                              return const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 20.0,
                                                    height: 20.0,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.0,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            final reversedIndex = messages.length - 1 - index;
                                            final message = messages[reversedIndex];
                                            final isMe = message.senderId == widget.currentUserId;

                                            bool showDateHeader = false;
                                            String dateStr = '';
                                            final msgDate = message.createdAt.toLocal();

                                            if (reversedIndex == 0) {
                                              showDateHeader = true;
                                            } else {
                                              final prevDate = messages[reversedIndex - 1].createdAt.toLocal();
                                              if (msgDate.year != prevDate.year ||
                                                  msgDate.month != prevDate.month ||
                                                  msgDate.day != prevDate.day) {
                                                showDateHeader = true;
                                              }
                                            }
                                            if (showDateHeader) {
                                              dateStr = ChatDateSeparator.formatDateHeader(msgDate);
                                            }

                                            // Hide header for consecutive messages from the same sender sent within the same minute
                                            bool showTimeHeader = true;
                                            if (reversedIndex > 0 && !showDateHeader) {
                                              final prevMessage = messages[reversedIndex - 1];
                                              final prevDate = prevMessage.createdAt.toLocal();
                                              final isSameSender = message.senderId == prevMessage.senderId;
                                              final isSameMinute = msgDate.minute == prevDate.minute &&
                                                  msgDate.hour == prevDate.hour &&
                                                  msgDate.day == prevDate.day &&
                                                  msgDate.month == prevDate.month &&
                                                  msgDate.year == prevDate.year;

                                              if (isSameSender && isSameMinute) {
                                                showTimeHeader = false;
                                              }
                                            }

                                            return Column(
                                              children: [
                                                if (showDateHeader)
                                                  ChatDateSeparator(date: dateStr),
                                                ChatBubbleWidget(
                                                  message: message,
                                                  isMe: isMe,
                                                  showTimeHeader: showTimeHeader,
                                                  onReply: () => _handleReplyMessage(message),
                                                  onEdit: () => _handleEditMessage(message, provider),
                                                  onDelete: () => _handleDeleteMessage(message, provider),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                        ),
                      ),

                      // Self-contained Chat Input Bar
                      ChatInputBarWidget(
                        currentUserId: widget.currentUserId,
                        currentUserType: widget.currentUserType,
                        replyingToMessage: _replyingToMessage,
                        onCancelReply: () => setState(() => _replyingToMessage = null),
                        onMessageSent: _scrollToBottom,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
