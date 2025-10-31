class BranchModel {
  final int id;
  final String name;
  final String? description;
  final String location;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final int? adminId;
  final bool isActive;
  final Map<String, dynamic>? admin;
  final List<Map<String, dynamic>>? users;
  final List<Map<String, dynamic>>? mcs;
  final Map<String, dynamic>? statistics;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchModel({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    this.address,
    this.phoneNumber,
    this.email,
    this.adminId,
    required this.isActive,
    this.admin,
    this.users,
    this.mcs,
    this.statistics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String,
      address: json['address'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      adminId: json['admin_id'] as int?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      admin: json['admin'] as Map<String, dynamic>?,
      users: json['users'] != null
          ? (json['users'] as List).cast<Map<String, dynamic>>()
          : null,
      mcs: json['mcs'] != null
          ? (json['mcs'] as List).cast<Map<String, dynamic>>()
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
      'description': description,
      'location': location,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'admin_id': adminId,
      'is_active': isActive,
      'admin': admin,
      'users': users,
      'mcs': mcs,
      'statistics': statistics,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BranchModel copyWith({
    int? id,
    String? name,
    String? description,
    String? location,
    String? address,
    String? phoneNumber,
    String? email,
    int? adminId,
    bool? isActive,
    Map<String, dynamic>? admin,
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? mcs,
    Map<String, dynamic>? statistics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      adminId: adminId ?? this.adminId,
      isActive: isActive ?? this.isActive,
      admin: admin ?? this.admin,
      users: users ?? this.users,
      mcs: mcs ?? this.mcs,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters for statistics
  int get totalUsers =>
      statistics?['total_users'] as int? ?? users?.length ?? 0;
  int get totalMCs => statistics?['total_mcs'] as int? ?? mcs?.length ?? 0;
  int get activeMCs => statistics?['active_mcs'] as int? ?? 0;
  int get pendingUsers => statistics?['pending_users'] as int? ?? 0;

  @override
  String toString() {
    return 'BranchModel(id: $id, name: $name, location: $location, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BranchModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
