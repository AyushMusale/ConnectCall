/// Public profile details for a user.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: (json['avatar'] ?? json['avatarUrl']) as String?,
      isOnline: (json['isOnline'] as bool?) ?? false,
      lastSeen: _parseDateTime(json['lastSeen']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      final dynamic dynamicVal = value;
      if (dynamicVal.toDate != null) {
        return dynamicVal.toDate() as DateTime;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatar != null) 'avatar': avatar,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
