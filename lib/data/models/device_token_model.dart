class DeviceTokenModel {
  final String? id;
  final String userId;
  final String token;
  final String platform; // 'ios' | 'android'
  final DateTime updatedAt;

  DeviceTokenModel({
    this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.updatedAt,
  });

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      token: json['token'] as String,
      platform: json['platform'] as String,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'token': token,
      'platform': platform,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
