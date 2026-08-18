import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../core/utils/common_ext.dart';

class MediaModel extends Equatable {
  final String? type;
  final String? url;
  final String? thumbnail;
  final Uint8List? bytes;
  final Uint8List? thumbnailBytes;
  final double? width;
  final double? height;
  final double? aspectRatio;

  bool get isVideo => type == 'video' || (url?.isVideoUrl ?? false);
  bool get isImage => type == 'image' || (type == null && (url?.isImageUrl ?? false));
  bool get isDocument => type == 'document' || type == 'file' || (!isVideo && !isImage);
  String get displayImageUrl => (thumbnail != null && thumbnail!.isNotEmpty) ? thumbnail! : (url ?? '');

  const MediaModel({
    this.type,
    this.url,
    this.thumbnail,
    this.bytes,
    this.thumbnailBytes,
    this.width,
    this.height,
    this.aspectRatio,
  });

  static MediaModel fromJson(dynamic json) {
    if (json is! Map) {
      return const MediaModel();
    }
    final w = (json['width'] as num?)?.toDouble();
    final h = (json['height'] as num?)?.toDouble();
    double? ratio = (json['aspect_ratio'] as num?)?.toDouble() ?? (json['aspectRatio'] as num?)?.toDouble();
    if (ratio == null && w != null && h != null && h > 0) {
      ratio = w / h;
    }

    return MediaModel(
      type: json['type']?.toString(),
      url: json['url']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      width: w,
      height: h,
      aspectRatio: ratio,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (type != null) data['type'] = type;
    if (url != null) data['url'] = url;
    if (thumbnail != null) data['thumbnail'] = thumbnail;
    if (width != null) data['width'] = width;
    if (height != null) data['height'] = height;
    if (aspectRatio != null) data['aspect_ratio'] = aspectRatio;
    return data;
  }

  MediaModel copyWith({
    String? type,
    String? url,
    String? thumbnail,
    Uint8List? bytes,
    Uint8List? thumbnailBytes,
    double? width,
    double? height,
    double? aspectRatio,
  }) {
    return MediaModel(
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      bytes: bytes ?? this.bytes,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  @override
  List<Object?> get props => [
        type,
        url,
        thumbnail,
        bytes,
        thumbnailBytes,
        width,
        height,
        aspectRatio,
      ];
}
