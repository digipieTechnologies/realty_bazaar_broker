// File: lib/models/chat_room_model.dart
// Purpose: Generic model for chat rooms supporting video request chats as well as direct / group chats.

import 'package:equatable/equatable.dart';

import 'video_request_model.dart';

class ChatRoomModel extends Equatable {
  final String id;
  final String videoRequestId;
  final String brokerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VideoRequestModel? videoRequest;
  final String? title;
  final String? roomType; // 'video_request', 'direct', 'group', etc.

  const ChatRoomModel({
    required this.id,
    this.videoRequestId = '',
    this.brokerId = '',
    required this.createdAt,
    required this.updatedAt,
    this.videoRequest,
    this.title,
    this.roomType = 'video_request',
  });

  factory ChatRoomModel.fromJson(dynamic json) {
    if (json is! Map) {
      return ChatRoomModel(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now());
    }

    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      videoRequestId: json['video_request_id']?.toString() ?? '',
      brokerId: json['broker_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      videoRequest: json['video_request'] != null ? VideoRequestModel.fromJson(json['video_request']) : null,
      title: json['title']?.toString(),
      roomType: json['room_type']?.toString() ?? 'video_request',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_request_id': videoRequestId,
      'broker_id': brokerId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      if (title != null) 'title': title,
      if (roomType != null) 'room_type': roomType,
    };
  }

  @override
  List<Object?> get props => [
    id,
    videoRequestId,
    brokerId,
    createdAt,
    updatedAt,
    videoRequest,
    title,
    roomType,
  ];
}
