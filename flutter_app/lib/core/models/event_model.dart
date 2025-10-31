class EventModel {
  final int id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? endDate;
  final String? location;
  final String visibility;
  final int? branchId;
  final int? mcId;
  final int createdBy;
  final bool isActive;
  final Map<String, dynamic>? createdByUser;
  final Map<String, dynamic>? branch;
  final Map<String, dynamic>? mc;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.endDate,
    this.location,
    required this.visibility,
    this.branchId,
    this.mcId,
    required this.createdBy,
    required this.isActive,
    this.createdByUser,
    this.branch,
    this.mc,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: DateTime.parse(json['event_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      location: json['location'] as String?,
      visibility: json['visibility'] as String,
      branchId: json['branch_id'] as int?,
      mcId: json['mc_id'] as int?,
      createdBy: json['created_by'] as int,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdByUser:
          json['createdBy'] ?? json['created_by_user'] as Map<String, dynamic>?,
      branch: json['branch'] as Map<String, dynamic>?,
      mc: json['mc'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'visibility': visibility,
      'branch_id': branchId,
      'mc_id': mcId,
      'created_by': createdBy,
      'is_active': isActive,
      'createdBy': createdByUser,
      'branch': branch,
      'mc': mc,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EventModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? endDate,
    String? location,
    String? visibility,
    int? branchId,
    int? mcId,
    int? createdBy,
    bool? isActive,
    Map<String, dynamic>? createdByUser,
    Map<String, dynamic>? branch,
    Map<String, dynamic>? mc,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      branchId: branchId ?? this.branchId,
      mcId: mcId ?? this.mcId,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdByUser: createdByUser ?? this.createdByUser,
      branch: branch ?? this.branch,
      mc: mc ?? this.mc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isUpcoming => eventDate.isAfter(DateTime.now());
  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
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

  Duration? get duration {
    if (endDate != null) {
      return endDate!.difference(eventDate);
    }
    return null;
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, eventDate: $eventDate, visibility: $visibility)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
