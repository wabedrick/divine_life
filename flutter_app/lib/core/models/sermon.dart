class Sermon {
  final int id;
  final String title;
  final String? description;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String? thumbnailUrl;
  final String category;
  final String? speaker;
  final DateTime sermonDate;
  final int? durationSeconds;
  final int viewCount;
  final bool isFeatured;
  final bool isActive;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sermon({
    required this.id,
    required this.title,
    this.description,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    this.thumbnailUrl,
    required this.category,
    this.speaker,
    required this.sermonDate,
    this.durationSeconds,
    required this.viewCount,
    required this.isFeatured,
    required this.isActive,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      youtubeUrl: json['youtube_url'] as String,
      youtubeVideoId: json['youtube_video_id'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      category: json['category'] as String,
      speaker: json['speaker'] as String?,
      sermonDate: DateTime.parse(json['sermon_date'] as String),
      durationSeconds: json['duration_seconds'] as int?,
      viewCount: json['view_count'] as int? ?? 0,
      isFeatured: _parseBool(json['is_featured']) ?? false,
      isActive: _parseBool(json['is_active']) ?? true,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : <String>[],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Helper method to parse boolean values from API (handles both bool and int)
  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'youtube_url': youtubeUrl,
      'youtube_video_id': youtubeVideoId,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'speaker': speaker,
      'sermon_date': sermonDate.toIso8601String().split('T')[0],
      'duration_seconds': durationSeconds,
      'view_count': viewCount,
      'is_featured': isFeatured,
      'is_active': isActive,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedDuration {
    if (durationSeconds == null) return 'Unknown';

    final duration = Duration(seconds: durationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

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
    return '${sermonDate.day} ${months[sermonDate.month - 1]} ${sermonDate.year}';
  }

  String get categoryDisplayName {
    const categoryNames = {
      'general': 'General',
      'sunday_service': 'Sunday Service',
      'special_event': 'Special Event',
      'bible_study': 'Bible Study',
      'youth': 'Youth Ministry',
      'children': 'Children\'s Ministry',
      'worship': 'Worship & Music',
    };
    return categoryNames[category] ?? category;
  }

  String get youtubeEmbedUrl {
    return 'https://www.youtube.com/embed/$youtubeVideoId';
  }

  String get youtubeThumbnail {
    return thumbnailUrl ??
        'https://img.youtube.com/vi/$youtubeVideoId/maxresdefault.jpg';
  }

  Sermon copyWith({
    int? id,
    String? title,
    String? description,
    String? youtubeUrl,
    String? youtubeVideoId,
    String? thumbnailUrl,
    String? category,
    String? speaker,
    DateTime? sermonDate,
    int? durationSeconds,
    int? viewCount,
    bool? isFeatured,
    bool? isActive,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sermon(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      speaker: speaker ?? this.speaker,
      sermonDate: sermonDate ?? this.sermonDate,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      viewCount: viewCount ?? this.viewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Sermon(id: $id, title: $title, category: $category, speaker: $speaker, date: $sermonDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sermon && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
