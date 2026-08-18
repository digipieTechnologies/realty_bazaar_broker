import 'package:equatable/equatable.dart';
import 'broker_model.dart';
import 'media_model.dart';
import 'property_model.dart';
import 'social_enums.dart';

class PostInsightsModel extends Equatable {
  final int impressions;
  final int reach;
  final int engagement;
  final int savedCount;
  final int videoViews;
  final int likeCount;
  final int commentCount;
  final int shareCount;

  const PostInsightsModel({
    this.impressions = 0,
    this.reach = 0,
    this.engagement = 0,
    this.savedCount = 0,
    this.videoViews = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
  });

  factory PostInsightsModel.fromJson(dynamic json) {
    if (json is! Map) {
      return const PostInsightsModel();
    }
    return PostInsightsModel(
      impressions: (json['impressions'] as num?)?.toInt() ?? 0,
      reach: (json['reach'] as num?)?.toInt() ?? 0,
      engagement: (json['engagement'] as num?)?.toInt() ?? 0,
      savedCount: (json['saved_count'] as num?)?.toInt() ?? 0,
      videoViews: (json['video_views'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'impressions': impressions,
      'reach': reach,
      'engagement': engagement,
      'saved_count': savedCount,
      'video_views': videoViews,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
    };
  }

  @override
  List<Object?> get props => [
        impressions,
        reach,
        engagement,
        savedCount,
        videoViews,
        likeCount,
        commentCount,
        shareCount,
      ];
}

class SocialPostModel extends Equatable {
  static const String tableName = "social_posts";

  final String? id;
  final String? platformPostId;
  final BrokerModel? brokerId;
  final PropertyModel? propertyId;
  final SocialPlatform? platform;
  final String? pageId;
  final String? postId;
  final String? caption;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? mediaType;
  final List<MediaModel>? mediaUrls;
  final String? permalink;
  final int? viewsCount;
  final int? commentCount;
  final int? likesCount;
  final int? shareCount;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PostInsightsModel? insights;
  final SocialPostModel? dbSocialPost;

  const SocialPostModel({
    this.id,
    this.platformPostId,
    this.brokerId,
    this.propertyId,
    this.platform,
    this.pageId,
    this.postId,
    this.caption,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaType,
    this.mediaUrls,
    this.permalink,
    this.viewsCount,
    this.commentCount,
    this.likesCount,
    this.shareCount,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.insights,
    this.dbSocialPost,
  });

  static SocialPostModel fromJson(dynamic json) {
    if (json is! Map) {
      return SocialPostModel(id: json?.toString());
    }

    List<MediaModel> mediaList = [];
    if (json['media_urls'] != null) {
      if (json['media_urls'] is List) {
        mediaList = (json['media_urls'] as List)
            .map((item) => MediaModel.fromJson(item))
            .toList();
      }
    }

    BrokerModel? parsedBroker;
    if (json['broker'] != null) {
      parsedBroker = BrokerModel.fromJson(json['broker']);
    } else if (json['broker_id'] != null) {
      parsedBroker = BrokerModel.fromJson(json['broker_id']);
    }

    PropertyModel? parsedProperty;
    if (json['properties'] != null) {
      parsedProperty = PropertyModel.fromJson(json['properties']);
    } else if (json['property'] != null) {
      parsedProperty = PropertyModel.fromJson(json['property']);
    } else if (json['property_id'] != null) {
      parsedProperty = PropertyModel.fromJson(json['property_id']);
    }

    PostInsightsModel? parsedInsights;
    if (json['insights'] != null) {
      parsedInsights = PostInsightsModel.fromJson(json['insights']);
    }

    SocialPostModel? parsedDbPost;
    if (json['social_post'] != null && json['social_post'] is Map) {
      parsedDbPost = SocialPostModel.fromJson(json['social_post']);
    }

    final singleMediaUrl = json['media_url']?.toString() ??
        (mediaList.isNotEmpty ? mediaList.first.url : null);
    final singleThumbnailUrl = json['thumbnail_url']?.toString() ??
        (mediaList.isNotEmpty ? mediaList.first.thumbnail : singleMediaUrl);

    final model = SocialPostModel(
      id: json['id']?.toString(),
      platformPostId: (json['platform_post_id'] ?? json['post_id'] ?? json['id'])?.toString(),
      brokerId: parsedBroker,
      propertyId: parsedProperty,
      platform: json['platform'] != null
          ? SocialPlatform.fromDbValue(json['platform'])
          : null,
      pageId: json['page_id']?.toString(),
      postId: (json['post_id'] ?? json['id'])?.toString(),
      caption: json['caption']?.toString() ?? json['message']?.toString(),
      mediaUrl: singleMediaUrl,
      thumbnailUrl: singleThumbnailUrl,
      mediaType: json['media_type']?.toString(),
      mediaUrls: mediaList,
      permalink: json['permalink']?.toString(),
      viewsCount: (json['views_count'] ?? json['view_count']) as int? ?? 0,
      commentCount: (json['comment_count'] ?? json['comments_count']) as int? ?? 0,
      likesCount: (json['likes_count'] ?? json['like_count']) as int? ?? 0,
      shareCount: (json['share_count'] ?? json['shares_count']) as int? ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())?.toLocal()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
              : null),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
      insights: parsedInsights,
      dbSocialPost: parsedDbPost,
    );

    if (model.dbSocialPost == null && model.isStoredInDb) {
      return model.copyWith(dbSocialPost: model);
    }

    return model;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    if (platformPostId != null) data['platform_post_id'] = platformPostId;
    data['broker_id'] = brokerId?.id;
    data['property_id'] = propertyId?.id;
    if (platform != null) data['platform'] = platform?.dbValue;
    if (pageId != null) data['page_id'] = pageId;
    if (postId != null) data['post_id'] = postId;
    data['caption'] = caption;
    if (mediaUrl != null) data['media_url'] = mediaUrl;
    if (thumbnailUrl != null) data['thumbnail_url'] = thumbnailUrl;
    if (mediaType != null) data['media_type'] = mediaType;
    if (mediaUrls != null) {
      data['media_urls'] = mediaUrls!.map((item) => item.toJson()).toList();
    }
    data['permalink'] = permalink;
    data['views_count'] = viewsCount;
    data['comment_count'] = commentCount;
    data['likes_count'] = likesCount;
    data['share_count'] = shareCount;
    if (publishedAt != null) {
      data['published_at'] = publishedAt?.toUtc().toIso8601String();
    }
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    if (insights != null) {
      data['insights'] = insights!.toJson();
    }
    if (dbSocialPost != null) {
      data['social_post'] = dbSocialPost!.toJson();
    }
    return data;
  }

  static const Object _sentinel = Object();

  SocialPostModel copyWith({
    String? id,
    String? platformPostId,
    BrokerModel? brokerId,
    PropertyModel? propertyId,
    SocialPlatform? platform,
    String? pageId,
    String? postId,
    String? caption,
    String? mediaUrl,
    String? thumbnailUrl,
    String? mediaType,
    List<MediaModel>? mediaUrls,
    String? permalink,
    int? viewsCount,
    int? commentCount,
    int? likesCount,
    int? shareCount,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    PostInsightsModel? insights,
    Object? dbSocialPost = _sentinel,
  }) {
    final metaId = platformPostId ?? this.platformPostId ?? postId ?? this.postId;
    final newDbPost = dbSocialPost == _sentinel
        ? this.dbSocialPost
        : (dbSocialPost as SocialPostModel?);

    final resolvedId = id ?? (newDbPost == null ? metaId : this.id);

    return SocialPostModel(
      id: resolvedId,
      platformPostId: platformPostId ?? this.platformPostId,
      brokerId: brokerId ?? this.brokerId,
      propertyId: propertyId ?? this.propertyId,
      platform: platform ?? this.platform,
      pageId: pageId ?? this.pageId,
      postId: postId ?? this.postId,
      caption: caption ?? this.caption,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaType: mediaType ?? this.mediaType,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      permalink: permalink ?? this.permalink,
      viewsCount: viewsCount ?? this.viewsCount,
      commentCount: commentCount ?? this.commentCount,
      likesCount: likesCount ?? this.likesCount,
      shareCount: shareCount ?? this.shareCount,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      insights: insights ?? this.insights,
      dbSocialPost: newDbPost,
    );
  }

  bool get isStoredInDb {
    if (dbSocialPost != null) return true;
    if (id != null &&
        id!.length == 36 &&
        id!.contains('-') &&
        platformPostId != null &&
        id != platformPostId) {
      return true;
    }
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        platformPostId,
        brokerId,
        propertyId,
        platform,
        pageId,
        postId,
        caption,
        mediaUrl,
        thumbnailUrl,
        mediaType,
        mediaUrls,
        permalink,
        viewsCount,
        commentCount,
        likesCount,
        shareCount,
        publishedAt,
        createdAt,
        updatedAt,
        insights,
        dbSocialPost,
      ];
}
