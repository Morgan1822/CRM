class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? role;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.role,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'Agent',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
