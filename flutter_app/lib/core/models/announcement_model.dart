// Announcement domain model used across the app
class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final String priority;
  final String visibility;
  final int? branchId;
  final int? mcId;
  final int createdBy;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic>? createdByUser;
  final Map<String, dynamic>? branch;
  final Map<String, dynamic>? mc;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.visibility,
    this.branchId,
    this.mcId,
    required this.createdBy,
    this.expiresAt,
    required this.isActive,
    this.createdByUser,
    this.branch,
    this.mc,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final idVal = map['id'] ?? map['ID'] ?? map['Id'];
        if (idVal is int) return idVal;
        if (idVal is String) return int.tryParse(idVal);
      }
      return null;
    }

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value == null) {
        return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
      return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    int parseCreatedBy(Map<String, dynamic> src) {
      final direct = parseId(src['created_by']);
      if (direct != null) return direct;
      final fromUser = src['createdBy'] ?? src['created_by_user'];
      final idFromUser = parseId(fromUser);
      if (idFromUser != null) return idFromUser;
      return parseId(src['created_by']) ?? 0;
    }

    final branchId = parseId(json['branch_id']);
    final mcId = parseId(json['mc_id']);
    final createdBy = parseCreatedBy(json);

    return AnnouncementModel(
      id: parseId(json['id']) ?? 0,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      priority: (json['priority'] ?? 'normal') as String,
      visibility: (json['visibility'] ?? 'all') as String,
      branchId: branchId,
      mcId: mcId,
      createdBy: createdBy,
      expiresAt: json['expires_at'] != null
          ? parseDate(json['expires_at'])
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdByUser: (json['createdBy'] ?? json['created_by_user']) is Map
          ? Map<String, dynamic>.from(
              json['createdBy'] ?? json['created_by_user'],
            )
          : null,
      branch: json['branch'] is Map
          ? Map<String, dynamic>.from(json['branch'])
          : null,
      mc: json['mc'] is Map ? Map<String, dynamic>.from(json['mc']) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'priority': priority,
      'visibility': visibility,
      'branch_id': branchId,
      'mc_id': mcId,
      'created_by': createdBy,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'createdBy': createdByUser,
      'branch': branch,
      'mc': mc,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AnnouncementModel copyWith({
    int? id,
    String? title,
    String? content,
    String? priority,
    String? visibility,
    int? branchId,
    int? mcId,
    int? createdBy,
    DateTime? expiresAt,
    bool? isActive,
    Map<String, dynamic>? createdByUser,
    Map<String, dynamic>? branch,
    Map<String, dynamic>? mc,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      visibility: visibility ?? this.visibility,
      branchId: branchId ?? this.branchId,
      mcId: mcId ?? this.mcId,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdByUser: createdByUser ?? this.createdByUser,
      branch: branch ?? this.branch,
      mc: mc ?? this.mc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isUrgent => priority == 'urgent';
  bool get isHigh => priority == 'high';
  bool get isNormal => priority == 'normal';
  bool get isLow => priority == 'low';

  String get priorityDisplayName {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'High';
      case 'normal':
        return 'Normal';
      case 'low':
        return 'Low';
      default:
        return priority.toUpperCase();
    }
  }

  String get visibilityDisplayName {
    switch (visibility) {
      case 'all':
        return 'Everyone';
      case 'branch':
        return 'Branch Only';
      case 'mc':
        return 'MC Only';
      default:
        return visibility.toUpperCase();
    }
  }

  int get priorityLevel {
    switch (priority) {
      case 'urgent':
        return 4;
      case 'high':
        return 3;
      case 'normal':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, title: $title, priority: $priority, visibility: $visibility)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnouncementModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
