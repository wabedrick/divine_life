class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final String role;
  final int? branchId;
  final int? mcId;
  final bool isApproved;
  final DateTime? approvedAt;
  final int? approvedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? branch;
  final Map<String, dynamic>? mc;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    required this.role,
    this.branchId,
    this.mcId,
    required this.isApproved,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.branch,
    this.mc,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      gender: json['gender'] as String?,
      role: json['role'] as String,
      branchId: json['branch_id'] as int?,
      mcId: json['mc_id'] as int?,
      isApproved: json['is_approved'] == 1 || json['is_approved'] == true,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      approvedBy: json['approved_by'] as int?,
      rejectionReason: json['rejection_reason'] as String?,
      branch: json['branch'] as Map<String, dynamic>?,
      mc: json['mc'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'role': role,
      'branch_id': branchId,
      'mc_id': mcId,
      'is_approved': isApproved,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
      'branch': branch,
      'mc': mc,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? birthDate,
    String? gender,
    String? role,
    int? branchId,
    int? mcId,
    bool? isApproved,
    DateTime? approvedAt,
    int? approvedBy,
    String? rejectionReason,
    Map<String, dynamic>? branch,
    Map<String, dynamic>? mc,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      mcId: mcId ?? this.mcId,
      isApproved: isApproved ?? this.isApproved,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      branch: branch ?? this.branch,
      mc: mc ?? this.mc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Role checking methods
  bool get isSuperAdmin => role == 'super_admin';
  bool get isBranchAdmin => role == 'branch_admin';
  bool get isMCLeader => role == 'mc_leader';
  bool get isMember => role == 'member';

  // Permission checking
  bool get canManageUsers => isSuperAdmin || isBranchAdmin;
  bool get canManageBranches => isSuperAdmin;
  bool get canManageMCs => isSuperAdmin || isBranchAdmin;
  bool get canCreateReports => isMCLeader;
  bool get canApproveReports => isSuperAdmin || isBranchAdmin;
  bool get canManageEvents => isSuperAdmin || isBranchAdmin || isMCLeader;
  bool get canManageAnnouncements =>
      isSuperAdmin || isBranchAdmin || isMCLeader;

  String get roleDisplayName {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'branch_admin':
        return 'Branch Admin';
      case 'mc_leader':
        return 'MC Leader';
      case 'member':
        return 'Member';
      default:
        return 'Unknown';
    }
  }

  String get fullName => name;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
