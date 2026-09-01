// File: lib/providers/chat/chat_provider.dart
// Purpose: Generic Chat state provider supporting room initialization, real-time message streaming, seamless scroll pagination, soft-delete, inline edit, and multi-media attachments via JSONB medias.

import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_storage_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/models.dart';

class ChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final int _limit = 20;
  int get limit => _limit;

  ChatRoomModel? _currentRoom;
  ChatRoomModel? get currentRoom => _currentRoom;

  List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  ChatMessageModel? _editingMessage;
  ChatMessageModel? get editingMessage => _editingMessage;

  void setEditingMessage(ChatMessageModel? message) {
    if (message != null &&
        (message.messageType != ChatMessageMessageType.text ||
            message.medias.isNotEmpty ||
            message.locationData != null)) {
      return;
    }
    _editingMessage = message;
    notifyListeners();
  }

  RealtimeChannel? _chatSubscription;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Initialize or fetch chat room for a specific video request ID
  Future<void> initChatRoom(String videoRequestId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentRoom = null;
    _messages = [];
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.rpc(
        'get_or_create_video_request_chat_room',
        params: {'p_video_request_id': videoRequestId},
      );

      if (response != null && response is Map<String, dynamic>) {
        _currentRoom = ChatRoomModel.fromJson(response);
        await fetchMessages(_currentRoom!.id);
        subscribeToRealtimeMessages(_currentRoom!.id);
      } else {
        _errorMessage = 'Could not load chat room.';
      }
    } catch (e) {
      debugPrint('[ChatProvider] Error initializing chat room: $e');
      _errorMessage = 'Error loading chat room.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resolveReplyMessages(List<ChatMessageModel> list) {
    final Map<String, ChatMessageModel> map = {for (var m in list) m.id: m};
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item.replyMessageId != null && item.replyMessage == null) {
        final parent = map[item.replyMessageId];
        if (parent != null) {
          list[i] = item.copyWith(replyMessage: parent);
        }
      }
    }
  }

  /// Fetch initial latest 20 non-deleted messages for a given chat room ID
  Future<void> fetchMessages(String roomId) async {
    try {
      _hasMore = true;
      _isLoadingMore = false;

      final response = await SupabaseConfig.client
          .from('chat_messages')
          .select('*')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(0, _limit - 1);

      final listData = response as List;
      final fetchedMessages = listData
          .map((json) => ChatMessageModel.fromJson(json))
          .toList()
          .reversed
          .toList();

      _messages = fetchedMessages;
      _resolveReplyMessages(_messages);
      if (listData.length < _limit) {
        _hasMore = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] Error fetching chat messages: $e');
    }
  }

  /// Fetch next page of 20 older non-deleted messages without jumping scroll view
  Future<void> fetchMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _currentRoom == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final currentOffset = _messages.length;
      final response = await SupabaseConfig.client
          .from('chat_messages')
          .select('*')
          .eq('room_id', _currentRoom!.id)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(currentOffset, currentOffset + _limit - 1);

      final listData = response as List;
      final olderMessages = listData
          .map((json) => ChatMessageModel.fromJson(json))
          .toList()
          .reversed
          .toList();

      if (olderMessages.isNotEmpty) {
        _messages.insertAll(0, olderMessages);
        _resolveReplyMessages(_messages);
      }

      if (listData.length < _limit) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('[ChatProvider] Error fetching older chat messages: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Soft-delete a chat message by setting is_deleted = true, deleted_at = now()
  Future<bool> deleteMessage(String messageId) async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await SupabaseConfig.client
          .from('chat_messages')
          .update({'is_deleted': true, 'deleted_at': nowUtc, 'updated_at': nowUtc})
          .eq('id', messageId);

      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ChatProvider] Error soft-deleting message: $e');
      return false;
    }
  }

  /// Edit text message content by ID
  Future<bool> editMessage(String messageId, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return false;

    _editingMessage = null;
    notifyListeners();

    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await SupabaseConfig.client
          .from('chat_messages')
          .update({'message': trimmed, 'is_edited': true, 'updated_at': nowUtc})
          .eq('id', messageId);

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          message: trimmed,
          isEdited: true,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[ChatProvider] Error editing message: $e');
      return false;
    }
  }

  /// Helper to upload local file attachment to Supabase Storage bucket 'chat_attachments'
  Future<String?> _uploadChatMedia(String localPath) async {
    return await SupabaseStorageService.uploadFile(filePath: localPath, bucketName: 'chat_attachments');
  }

  /// Send a text message with single or multi-media attachments via JSONB medias or locationData
  Future<bool> sendMessage({
    required String senderId,
    required String senderType,
    required String message,
    ChatMessageMessageType messageType = ChatMessageMessageType.text,
    List<MediaModel> attachmentMedias = const [],
    Map<String, dynamic>? locationData,
    String? replyMessageId,
  }) async {
    if (_currentRoom == null ||
        (message.trim().isEmpty && attachmentMedias.isEmpty && locationData == null)) {
      return false;
    }

    _isSending = true;
    notifyListeners();

    try {
      List<MediaModel> uploadedMedias = [];
      if (attachmentMedias.isNotEmpty) {
        for (final item in attachmentMedias) {
          String? uploadedUrl;
          String? uploadedThumb;

          if (item.url != null && item.url!.isNotEmpty) {
            uploadedUrl = await _uploadChatMedia(item.url!);
          }

          if (item.thumbnailBytes != null) {
            final tempPath =
                '${io.Directory.systemTemp.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final tempFile = io.File(tempPath);
            await tempFile.writeAsBytes(item.thumbnailBytes!);
            uploadedThumb = await _uploadChatMedia(tempFile.path);
            try {
              await tempFile.delete();
            } catch (_) {}
          }

          uploadedMedias.add(
            item.copyWith(url: uploadedUrl ?? item.url, thumbnail: uploadedThumb ?? item.thumbnail),
          );
        }
      }

      ChatMessageMessageType effectiveMessageType = messageType;
      if (locationData != null || messageType == ChatMessageMessageType.location) {
        effectiveMessageType = ChatMessageMessageType.location;
      } else if (uploadedMedias.isNotEmpty) {
        effectiveMessageType = ChatMessageMessageType.document;
      }

      final payload = {
        'room_id': _currentRoom!.id,
        'sender_id': senderId,
        'sender_type': senderType,
        'message': message.trim(),
        'message_type': effectiveMessageType.dbValue,
        'medias': uploadedMedias.map((m) => m.toJson()).toList(),
        'location_data': locationData,
        'reply_message_id': replyMessageId,
        'is_edited': false,
        'is_deleted': false,
      };

      final response = await SupabaseConfig.client.from('chat_messages').insert(payload).select('*').single();

      var newMessage = ChatMessageModel.fromJson(response);
      if (newMessage.replyMessageId != null && newMessage.replyMessage == null) {
        final parentIndex = _messages.indexWhere((m) => m.id == newMessage.replyMessageId);
        if (parentIndex != -1) {
          newMessage = newMessage.copyWith(replyMessage: _messages[parentIndex]);
        }
      }

      if (!_messages.any((m) => m.id == newMessage.id)) {
        _messages.add(newMessage);
      }

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ChatProvider] Error sending message: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Subscribe to Supabase Realtime postgres changes for live incoming/edited/deleted messages
  void subscribeToRealtimeMessages(String roomId) {
    _chatSubscription?.unsubscribe();

    _chatSubscription = SupabaseConfig.client
        .channel('chat_room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (payload) {
            debugPrint('[ChatProvider] Realtime Message Event: ${payload.eventType}');
            if (payload.eventType == PostgresChangeEvent.insert) {
              final newJson = payload.newRecord;
              if (newJson.isNotEmpty && newJson['is_deleted'] != true) {
                var newMessage = ChatMessageModel.fromJson(newJson);
                if (newMessage.replyMessageId != null && newMessage.replyMessage == null) {
                  final parent = _messages.where((m) => m.id == newMessage.replyMessageId).firstOrNull;
                  if (parent != null) {
                    newMessage = newMessage.copyWith(replyMessage: parent);
                  }
                }
                if (!_messages.any((m) => m.id == newMessage.id)) {
                  _messages.add(newMessage);
                  notifyListeners();
                }
              }
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final updatedJson = payload.newRecord;
              if (updatedJson.isNotEmpty) {
                var updatedMsg = ChatMessageModel.fromJson(updatedJson);
                if (updatedMsg.isDeleted) {
                  _messages.removeWhere((m) => m.id == updatedMsg.id);
                } else {
                  final idx = _messages.indexWhere((m) => m.id == updatedMsg.id);
                  if (idx != -1) {
                    final existingMsg = _messages[idx];
                    final replyMsgToKeep =
                        existingMsg.replyMessage ??
                        (updatedMsg.replyMessageId != null
                            ? _messages.where((m) => m.id == updatedMsg.replyMessageId).firstOrNull
                            : null);
                    if (replyMsgToKeep != null) {
                      updatedMsg = updatedMsg.copyWith(replyMessage: replyMsgToKeep);
                    }
                    _messages[idx] = updatedMsg;
                  }
                }
                notifyListeners();
              }
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final deletedId = payload.oldRecord['id']?.toString();
              if (deletedId != null) {
                _messages.removeWhere((m) => m.id == deletedId);
                notifyListeners();
              }
            }
          },
        );

    _chatSubscription!.subscribe();
  }

  /// Unsubscribe realtime subscription and reset state
  void disposeChat() {
    _chatSubscription?.unsubscribe();
    _chatSubscription = null;
    _currentRoom = null;
    _messages = [];
    _editingMessage = null;
    _hasMore = true;
    _isLoadingMore = false;
  }

  /// Reset state on user sign out
  void clear() {
    disposeChat();
    notifyListeners();
  }

  @override
  void dispose() {
    disposeChat();
    super.dispose();
  }
}
