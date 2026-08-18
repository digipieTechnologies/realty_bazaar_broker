// File: lib/modules/chat/widgets/chat_input_bar_widget.dart
// Purpose: Self-contained Chat input bar widget managing TextEditingController, FocusNode, + attachment options popup menu (Media & Location), attachment previews, reply strip, and ChatProvider message dispatching.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/app_colors.dart';
import '../../../core/constants/chat_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/utils/media_picker_helper.dart';
import '../../../models/models.dart';
import '../../../providers/chat/chat_provider.dart';
import '../../../widgets/buttons/app_popup_menu_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/dividers/app_divider.dart';
import 'chat_attachment_preview_widget.dart';
import 'chat_edit_preview_widget.dart';
import 'chat_reply_preview_widget.dart';

class ChatInputBarWidget extends StatefulWidget {
  final String currentUserId;
  final String currentUserType; // 'broker', 'marketing', 'admin', etc.
  final ChatMessageModel? replyingToMessage;
  final VoidCallback? onCancelReply;
  final VoidCallback? onMessageSent;

  const ChatInputBarWidget({
    super.key,
    required this.currentUserId,
    required this.currentUserType,
    this.replyingToMessage,
    this.onCancelReply,
    this.onMessageSent,
  });

  @override
  State<ChatInputBarWidget> createState() => _ChatInputBarWidgetState();
}

class _ChatInputBarWidgetState extends State<ChatInputBarWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  List<MediaModel> _selectedAttachments = [];
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant ChatInputBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyingToMessage != null && oldWidget.replyingToMessage != widget.replyingToMessage) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      if (provider.editingMessage != null) {
        provider.setEditingMessage(null);
      }
      _controller.clear();
      if (_selectedAttachments.isNotEmpty) {
        setState(() {
          _selectedAttachments = [];
        });
      }
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleShareLocation(ChatProvider provider) async {
    if (provider.editingMessage != null) {
      provider.setEditingMessage(null);
      _controller.clear();
    }

    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: 'Share Location?',
      description: 'Are you sure you want to share your location with this user?',
      type: DialogType.info,
      confirmText: 'Share Location',
      cancelText: 'Cancel',
    );

    if (confirmed != true || !mounted) return;

    final position = await LocationHelper.getCurrentLocation(context);
    if (position == null || !mounted) return;

    final success = await provider.sendMessage(
      senderId: widget.currentUserId,
      senderType: widget.currentUserType,
      message: 'Location',
      messageType: ChatMessageMessageType.location,
      locationData: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
    );

    if (success) {
      widget.onMessageSent?.call();
    }
  }

  Future<void> _handlePickMedia(ChatProvider provider) async {
    final picked = await MediaPickerHelper.pickMedia(
      context: context,
      currentMedias: _selectedAttachments,
      maxMedia: ChatConstants.maxAttachmentsPerMessage,
    );

    if (picked.isNotEmpty) {
      if (provider.editingMessage != null) {
        provider.setEditingMessage(null);
        _controller.clear();
      }
      setState(() {
        _selectedAttachments = [..._selectedAttachments, ...picked];
      });
    }
  }

  Future<void> _handleSendMessage(ChatProvider provider) async {
    String text = _controller.text.trim();

    // If in editing mode, dispatch edit operation directly without dialog
    final editingModel = provider.editingMessage;
    if (editingModel != null) {
      if (text.isEmpty) return;
      _controller.clear();
      final success = await provider.editMessage(editingModel.id, text);
      if (success) {
        widget.onMessageSent?.call();
      }
      return;
    }

    final replyId = widget.replyingToMessage?.id;
    final attachments = List<MediaModel>.from(_selectedAttachments);

    if (text.isEmpty && attachments.isEmpty) return;

    _controller.clear();
    setState(() {
      _selectedAttachments = [];
    });
    widget.onCancelReply?.call();

    final success = await provider.sendMessage(
      senderId: widget.currentUserId,
      senderType: widget.currentUserType,
      message: text,
      attachmentMedias: attachments,
      replyMessageId: replyId,
    );

    if (success) {
      widget.onMessageSent?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final editingModel = provider.editingMessage;

        // Auto-fill text and focus when editing mode is triggered, clear selected attachments & reply mode
        if (editingModel != null && _editingMessageId != editingModel.id) {
          _editingMessageId = editingModel.id;
          _controller.text = editingModel.message ?? '';
          if (widget.replyingToMessage != null) {
            widget.onCancelReply?.call();
          }
          if (_selectedAttachments.isNotEmpty) {
            _selectedAttachments = [];
          }
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && provider.editingMessage?.id == editingModel.id) {
              _focusNode.requestFocus();
            }
          });
        } else if (editingModel == null && _editingMessageId != null) {
          _editingMessageId = null;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Top Divider separating message list from input area
            const AppDivider(margin: EdgeInsets.only(top: 4.0, bottom: 8.0)),

            // 2. Edit Message Preview Strip (Prioritized)
            if (editingModel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ChatEditPreviewWidget(
                  editingMessage: editingModel,
                  onCancelEdit: () {
                    provider.setEditingMessage(null);
                    _controller.clear();
                  },
                ),
              )

            // 3. Reply Preview Strip
            else if (widget.replyingToMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ChatReplyPreviewWidget(
                  replyingToMessage: widget.replyingToMessage!,
                  onCancelReply: widget.onCancelReply ?? () {},
                ),
              ),

            // 3. Multi-Attachment Preview Strip
            if (_selectedAttachments.isNotEmpty) ...[
              ChatAttachmentPreviewWidget(
                attachments: _selectedAttachments,
                onRemoveAttachment: (index) {
                  setState(() {
                    _selectedAttachments.removeAt(index);
                  });
                },
              ),
              const AppDivider(margin: EdgeInsets.only(top: 8.0, bottom: 8.0)),
            ],

            // 4. Input Row (+ button popup menu, TextField, Send button)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
              child: Row(
                children: [
                  AppPopupMenuButton<String>(
                    triggerWidget: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 26.0,
                      ),
                    ),
                    items: const [
                      AppPopupMenuItem<String>(
                        value: 'media',
                        label: 'Photos & Videos',
                        iconData: Icons.photo_library_rounded,
                        iconColor: AppColors.primary,
                      ),
                      AppPopupMenuItem<String>(
                        value: 'location',
                        label: 'Location',
                        iconData: Icons.location_on_rounded,
                        iconColor: AppColors.secondary,
                      ),
                    ],
                    onSelected: (action) {
                      if (action == 'media') {
                        _handlePickMedia(provider);
                      } else if (action == 'location') {
                        _handleShareLocation(provider);
                      }
                    },
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            final isShift = HardwareKeyboard.instance.isShiftPressed;
                            if (!isShift) {
                              _handleSendMessage(provider);
                              return KeyEventResult.handled;
                            }
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontSize: 14.0),
                        decoration: InputDecoration(
                          hintText: context.tr('type_a_message'),
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14.0),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  InkWell(
                    borderRadius: BorderRadius.circular(22.0),
                    onTap: provider.isSending ? null : () => _handleSendMessage(provider),
                    child: Container(
                      width: 44.0,
                      height: 44.0,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: provider.isSending
                          ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20.0,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
