/// Public profile details for a user.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: (json['avatar'] ?? json['avatarUrl']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatar != null) 'avatar': avatar,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
    );
  }
}
