// File: lib/models/notification_model.dart
// Purpose: Type-safe model for notifications supporting VideoRequestModel relations, receiverIds array, metadata JSON, and copyWith.

import 'package:equatable/equatable.dart';
import 'notification_enums.dart';
import 'user_model.dart';
import 'video_request_model.dart';

class NotificationModel extends Equatable {
  static String tableName = "notifications";

  final String? id;
  final UserModel? senderId;
  final List<String>? receiverIds;
  final VideoRequestModel? videoRequest;
  final NotificationType type;
  final String title;
  final String description;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;

  const NotificationModel({
    this.id,
    this.senderId,
    this.receiverIds,
    this.videoRequest,
    this.type = NotificationType.lead,
    this.title = '',
    this.description = '',
    this.data,
    this.createdAt,
  });

  static NotificationModel fromJson(dynamic json) {
    if (json is! Map) {
      return NotificationModel(id: json?.toString());
    }

    // 1. Parse senderId
    UserModel? parsedSender;
    if (json['sender_id'] != null) {
      parsedSender = UserModel.fromJson(json['sender_id']);
    } else if (json['sender'] != null) {
      parsedSender = UserModel.fromJson(json['sender']);
    }

    // 2. Parse receiverIds array (supports 'receiver_ids', 'receiver_id')
    List<String>? parsedReceiverIds;
    if (json['receiver_ids'] is List) {
      parsedReceiverIds = (json['receiver_ids'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['receiver_id'] != null) {
      final singleId = json['receiver_id'].toString();
      if (singleId.isNotEmpty) {
        parsedReceiverIds = [singleId];
      }
    }

    // 3. Parse Metadata JSON
    Map<String, dynamic>? parsedData;
    if (json['data'] is Map) {
      parsedData = Map<String, dynamic>.from(json['data'] as Map);
    }

    // 4. Parse VideoRequestModel relation object or string ID
    VideoRequestModel? parsedVideoRequest;
    if (json['video_request'] != null) {
      parsedVideoRequest = VideoRequestModel.fromJson(json['video_request']);
    } else if (json['video_request_id'] != null) {
      final reqVal = json['video_request_id'];
      if (reqVal is Map) {
        parsedVideoRequest = VideoRequestModel.fromJson(reqVal);
      } else {
        final reqIdStr = reqVal.toString();
        if (reqIdStr.isNotEmpty) {
          parsedVideoRequest = VideoRequestModel.fromJson({'id': reqIdStr});
        }
      }
    } else if (parsedData?['video_request_id'] != null) {
      final reqIdStr = parsedData!['video_request_id']?.toString();
      if (reqIdStr != null && reqIdStr.isNotEmpty) {
        parsedVideoRequest = VideoRequestModel.fromJson({'id': reqIdStr});
      }
    }

    return NotificationModel(
      id: json['id']?.toString(),
      senderId: parsedSender,
      receiverIds: parsedReceiverIds,
      videoRequest: parsedVideoRequest,
      type: NotificationType.fromDbValue(
        json['notification_type']?.toString() ?? json['type']?.toString(),
      ),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['body']?.toString() ?? '',
      data: parsedData,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {};
    if (id != null) jsonMap['id'] = id;
    if (senderId?.id != null) jsonMap['sender_id'] = senderId?.id;
    if (receiverIds != null && receiverIds!.isNotEmpty) {
      jsonMap['receiver_ids'] = receiverIds;
    }
    if (videoRequest?.id != null) jsonMap['video_request_id'] = videoRequest?.id;
    jsonMap['notification_type'] = type.dbValue;
    jsonMap['title'] = title;
    jsonMap['description'] = description;
    if (data != null) jsonMap['data'] = data;
    if (createdAt != null) {
      jsonMap['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    return jsonMap;
  }

  NotificationModel copyWith({
    String? id,
    UserModel? senderId,
    List<String>? receiverIds,
    VideoRequestModel? videoRequest,
    NotificationType? type,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverIds: receiverIds ?? this.receiverIds,
      videoRequest: videoRequest ?? this.videoRequest,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverIds,
        videoRequest,
        type,
        title,
        description,
        data,
        createdAt,
      ];
}
