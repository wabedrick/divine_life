class MCModel {
  final int id;
  final String name;
  final String? vision;
  final String? goals;
  final String? purpose;
  final String location;
  final int leaderId;
  final String? leaderPhone;
  final int branchId;
  final bool isActive;
  final Map<String, dynamic>? leader;
  final Map<String, dynamic>? branch;
  final List<Map<String, dynamic>>? members;
  final Map<String, dynamic>? statistics;
  final DateTime createdAt;
  final DateTime updatedAt;

  MCModel({
    required this.id,
    required this.name,
    this.vision,
    this.goals,
    this.purpose,
    required this.location,
    required this.leaderId,
    this.leaderPhone,
    required this.branchId,
    required this.isActive,
    this.leader,
    this.branch,
    this.members,
    this.statistics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MCModel.fromJson(Map<String, dynamic> json) {
    return MCModel(
      id: json['id'] as int,
      name: json['name'] as String,
      vision: json['vision'] as String?,
      goals: json['goals'] as String?,
      purpose: json['purpose'] as String?,
      location: json['location'] as String,
      leaderId: json['leader_id'] as int,
      leaderPhone: json['leader_phone'] as String?,
      branchId: json['branch_id'] as int,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      leader: json['leader'] as Map<String, dynamic>?,
      branch: json['branch'] as Map<String, dynamic>?,
      members: json['members'] != null
          ? (json['members'] as List).cast<Map<String, dynamic>>()
          : null,
      statistics: json['statistics'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vision': vision,
      'goals': goals,
      'purpose': purpose,
      'location': location,
      'leader_id': leaderId,
      'leader_phone': leaderPhone,
      'branch_id': branchId,
      'is_active': isActive,
      'leader': leader,
      'branch': branch,
      'members': members,
      'statistics': statistics,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MCModel copyWith({
    int? id,
    String? name,
    String? vision,
    String? goals,
    String? purpose,
    String? location,
    int? leaderId,
    String? leaderPhone,
    int? branchId,
    bool? isActive,
    Map<String, dynamic>? leader,
    Map<String, dynamic>? branch,
    List<Map<String, dynamic>>? members,
    Map<String, dynamic>? statistics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MCModel(
      id: id ?? this.id,
      name: name ?? this.name,
      vision: vision ?? this.vision,
      goals: goals ?? this.goals,
      purpose: purpose ?? this.purpose,
      location: location ?? this.location,
      leaderId: leaderId ?? this.leaderId,
      leaderPhone: leaderPhone ?? this.leaderPhone,
      branchId: branchId ?? this.branchId,
      isActive: isActive ?? this.isActive,
      leader: leader ?? this.leader,
      branch: branch ?? this.branch,
      members: members ?? this.members,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters for statistics
  int get totalMembers =>
      statistics?['total_members'] as int? ?? members?.length ?? 0;
  int get activeMembers => statistics?['active_members'] as int? ?? 0;

  @override
  String toString() {
    return 'MCModel(id: $id, name: $name, location: $location, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MCModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
