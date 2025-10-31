class SocialMediaPost {
  final int id;
  final String title;
  final String? description;
  final String postUrl;
  final String platform;
  final String? thumbnailUrl;
  final String mediaType;
  final String category;
  final DateTime postDate;
  final int likeCount;
  final int shareCount;
  final int commentCount;
  final bool isFeatured;
  final bool isActive;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;

  SocialMediaPost({
    required this.id,
    required this.title,
    this.description,
    required this.postUrl,
    required this.platform,
    this.thumbnailUrl,
    required this.mediaType,
    required this.category,
    required this.postDate,
    required this.likeCount,
    required this.shareCount,
    required this.commentCount,
    required this.isFeatured,
    required this.isActive,
    required this.hashtags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialMediaPost.fromJson(Map<String, dynamic> json) {
    return SocialMediaPost(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      postUrl: json['post_url'] as String,
      platform: json['platform'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      mediaType: json['media_type'] as String,
      category: json['category'] as String,
      postDate: DateTime.parse(json['post_date'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      hashtags: json['hashtags'] != null
          ? List<String>.from(json['hashtags'] as List)
          : <String>[],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'post_url': postUrl,
      'platform': platform,
      'thumbnail_url': thumbnailUrl,
      'media_type': mediaType,
      'category': category,
      'post_date': postDate.toIso8601String().split('T')[0],
      'like_count': likeCount,
      'share_count': shareCount,
      'comment_count': commentCount,
      'is_featured': isFeatured,
      'is_active': isActive,
      'hashtags': hashtags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${postDate.day} ${months[postDate.month - 1]} ${postDate.year}';
  }

  String get platformDisplayName {
    const platformNames = {
      'instagram': 'Instagram',
      'facebook': 'Facebook',
      'tiktok': 'TikTok',
      'twitter': 'Twitter',
      'youtube_shorts': 'YouTube Shorts',
    };
    return platformNames[platform] ?? platform;
  }

  String get categoryDisplayName {
    const categoryNames = {
      'general': 'General',
      'devotional': 'Devotional',
      'worship': 'Worship',
      'testimony': 'Testimony',
      'announcement': 'Announcement',
      'prayer': 'Prayer',
      'outreach': 'Outreach',
    };
    return categoryNames[category] ?? category;
  }

  String get mediaTypeDisplayName {
    const mediaTypeNames = {
      'video': 'Video',
      'image': 'Image',
      'carousel': 'Carousel',
    };
    return mediaTypeNames[mediaType] ?? mediaType;
  }

  String get platformIcon {
    const platformIcons = {
      'instagram': 'assets/icons/instagram.png',
      'facebook': 'assets/icons/facebook.png',
      'tiktok': 'assets/icons/tiktok.png',
      'twitter': 'assets/icons/twitter.png',
      'youtube_shorts': 'assets/icons/youtube.png',
    };
    return platformIcons[platform] ?? 'assets/icons/social_media.png';
  }

  int get totalEngagement => likeCount + shareCount + commentCount;

  String get formattedEngagement {
    final total = totalEngagement;
    if (total >= 1000000) {
      return '${(total / 1000000).toStringAsFixed(1)}M';
    } else if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}K';
    } else {
      return total.toString();
    }
  }

  String get engagementBreakdown {
    final parts = <String>[];
    if (likeCount > 0) parts.add('$likeCount likes');
    if (shareCount > 0) parts.add('$shareCount shares');
    if (commentCount > 0) parts.add('$commentCount comments');
    return parts.isEmpty ? 'No engagement yet' : parts.join(' • ');
  }

  SocialMediaPost copyWith({
    int? id,
    String? title,
    String? description,
    String? postUrl,
    String? platform,
    String? thumbnailUrl,
    String? mediaType,
    String? category,
    DateTime? postDate,
    int? likeCount,
    int? shareCount,
    int? commentCount,
    bool? isFeatured,
    bool? isActive,
    List<String>? hashtags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialMediaPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      postUrl: postUrl ?? this.postUrl,
      platform: platform ?? this.platform,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaType: mediaType ?? this.mediaType,
      category: category ?? this.category,
      postDate: postDate ?? this.postDate,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      commentCount: commentCount ?? this.commentCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      hashtags: hashtags ?? this.hashtags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SocialMediaPost(id: $id, title: $title, platform: $platform, category: $category, date: $postDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialMediaPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
