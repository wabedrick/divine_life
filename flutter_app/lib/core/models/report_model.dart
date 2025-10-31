class ReportModel {
  final int id;
  final String type;
  final String week;
  final String reportDate;
  final int mcId;
  final int submittedBy;
  final String status;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewComments;

  // Report data fields
  final int attendance;
  final int newMembers;
  final int baptisms;
  final int salvations;
  final int testimonies;
  final double offerings;
  final String? evangelismActivities;
  final String? discipleshipActivities;
  final String? communityOutreach;
  final String? challenges;
  final String? prayerRequests;
  final String? praise;
  final String? comments;

  final Map<String, dynamic>? mc;
  final Map<String, dynamic>? submittedByUser;
  final Map<String, dynamic>? reviewedByUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    required this.id,
    required this.type,
    required this.week,
    required this.reportDate,
    required this.mcId,
    required this.submittedBy,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewComments,
    required this.attendance,
    required this.newMembers,
    required this.baptisms,
    required this.salvations,
    required this.testimonies,
    required this.offerings,
    this.evangelismActivities,
    this.discipleshipActivities,
    this.communityOutreach,
    this.challenges,
    this.prayerRequests,
    this.praise,
    this.comments,
    this.mc,
    this.submittedByUser,
    this.reviewedByUser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as int,
      type: json['type'] as String,
      week: json['week'] as String,
      reportDate: json['report_date'] as String,
      mcId: json['mc_id'] as int,
      submittedBy: json['submitted_by'] as int,
      status: json['status'] as String,
      reviewedBy: json['reviewed_by'] as int?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      reviewComments: json['review_comments'] as String?,
      attendance: json['attendance'] as int? ?? 0,
      newMembers: json['new_members'] as int? ?? 0,
      baptisms: json['baptisms'] as int? ?? 0,
      salvations: json['salvations'] as int? ?? 0,
      testimonies: json['testimonies'] as int? ?? 0,
      offerings: (json['offerings'] as num?)?.toDouble() ?? 0.0,
      evangelismActivities: json['evangelism_activities'] as String?,
      discipleshipActivities: json['discipleship_activities'] as String?,
      communityOutreach: json['community_outreach'] as String?,
      challenges: json['challenges'] as String?,
      prayerRequests: json['prayer_requests'] as String?,
      praise: json['praise'] as String?,
      comments: json['comments'] as String?,
      mc: json['mc'] as Map<String, dynamic>?,
      submittedByUser:
          json['submittedBy'] ?? json['user'] as Map<String, dynamic>?,
      reviewedByUser: json['reviewedBy'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'week': week,
      'report_date': reportDate,
      'mc_id': mcId,
      'submitted_by': submittedBy,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_comments': reviewComments,
      'attendance': attendance,
      'new_members': newMembers,
      'baptisms': baptisms,
      'salvations': salvations,
      'testimonies': testimonies,
      'offerings': offerings,
      'evangelism_activities': evangelismActivities,
      'discipleship_activities': discipleshipActivities,
      'community_outreach': communityOutreach,
      'challenges': challenges,
      'prayer_requests': prayerRequests,
      'praise': praise,
      'comments': comments,
      'mc': mc,
      'submittedBy': submittedByUser,
      'reviewedBy': reviewedByUser,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReportModel copyWith({
    int? id,
    String? type,
    String? week,
    String? reportDate,
    int? mcId,
    int? submittedBy,
    String? status,
    int? reviewedBy,
    DateTime? reviewedAt,
    String? reviewComments,
    int? attendance,
    int? newMembers,
    int? baptisms,
    int? salvations,
    int? testimonies,
    double? offerings,
    String? evangelismActivities,
    String? discipleshipActivities,
    String? communityOutreach,
    String? challenges,
    String? prayerRequests,
    String? praise,
    String? comments,
    Map<String, dynamic>? mc,
    Map<String, dynamic>? submittedByUser,
    Map<String, dynamic>? reviewedByUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      type: type ?? this.type,
      week: week ?? this.week,
      reportDate: reportDate ?? this.reportDate,
      mcId: mcId ?? this.mcId,
      submittedBy: submittedBy ?? this.submittedBy,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewComments: reviewComments ?? this.reviewComments,
      attendance: attendance ?? this.attendance,
      newMembers: newMembers ?? this.newMembers,
      baptisms: baptisms ?? this.baptisms,
      salvations: salvations ?? this.salvations,
      testimonies: testimonies ?? this.testimonies,
      offerings: offerings ?? this.offerings,
      evangelismActivities: evangelismActivities ?? this.evangelismActivities,
      discipleshipActivities:
          discipleshipActivities ?? this.discipleshipActivities,
      communityOutreach: communityOutreach ?? this.communityOutreach,
      challenges: challenges ?? this.challenges,
      prayerRequests: prayerRequests ?? this.prayerRequests,
      praise: praise ?? this.praise,
      comments: comments ?? this.comments,
      mc: mc ?? this.mc,
      submittedByUser: submittedByUser ?? this.submittedByUser,
      reviewedByUser: reviewedByUser ?? this.reviewedByUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'weekly':
        return 'Weekly Report';
      case 'monthly':
        return 'Monthly Report';
      case 'special':
        return 'Special Report';
      default:
        return type.toUpperCase();
    }
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, type: $type, week: $week, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
