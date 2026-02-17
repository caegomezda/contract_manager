class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // super_admin, admin, supervisor, worker
  final String? parentAdminId;
  final String? supervisorId;
  final String? authCode;
  final DateTime? authValidUntil;
  final bool isSuperAdmin;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.parentAdminId,
    this.supervisorId,
    this.authCode,
    this.authValidUntil,
    this.isSuperAdmin = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'worker',
      parentAdminId: data['parent_admin_id'],
      supervisorId: data['supervisor_id'],
      authCode: data['auth_code'],
      authValidUntil: data['auth_valid_until'] != null 
          ? DateTime.tryParse(data['auth_valid_until'].toString()) 
          : null,
      isSuperAdmin: data['is_super_admin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'parent_admin_id': parentAdminId,
      'supervisor_id': supervisorId,
      'auth_code': authCode,
      'auth_valid_until': authValidUntil?.toIso8601String(),
      'is_super_admin': isSuperAdmin,
    };
  }
}