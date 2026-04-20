class UserModel {
  final String id;
  final String username;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? 'pegawai').toString(),
      isActive: (json['is_active'] ?? true) as bool,
    );
  }
}
