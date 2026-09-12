import '../../../models/profile_model.dart';

/// Model representing a contact matching the whiteboard schema:
/// `{ otherUserId, otherUserName, otherUserAvatar }`.
class ContactModel {
  const ContactModel({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.isGroup = false,
  });

  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isGroup;

  /// Convenience / backward-compatible getters
  String get id => otherUserId;
  String get name => otherUserName;
  String? get avatarUrl => otherUserAvatar;

  /// Factory constructor to convert from [ProfileModel].
  factory ContactModel.fromProfile(ProfileModel profile) {
    return ContactModel(
      otherUserId: profile.id,
      otherUserName: profile.name,
      otherUserAvatar: profile.avatar,
    );
  }

  /// Factory constructor to parse contact from JSON map.
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      otherUserId: (json['otherUserId'] ?? json['id'] ?? '') as String,
      otherUserName: (json['otherUserName'] ?? json['name'] ?? '') as String,
      otherUserAvatar:
          (json['otherUserAvatar'] ?? json['avatarUrl'] ?? json['avatar'])
              as String?,
      isGroup: json['isGroup'] as bool? ?? false,
    );
  }

  /// Converts this contact to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'isGroup': isGroup,
    };
  }

  ContactModel copyWith({
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    bool? isGroup,
  }) {
    return ContactModel(
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      isGroup: isGroup ?? this.isGroup,
    );
  }

  /// Sample contacts matching the contact page mock design.
  static const List<ContactModel> sampleContacts = [
    ContactModel(
      otherUserId: 'cnt-1',
      otherUserName: 'Aditi Sharma',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-2',
      otherUserName: 'Rohan Mehta',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-3',
      otherUserName: 'Priya Nair',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-4',
      otherUserName: 'College Buddies',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=150',
      isGroup: true,
    ),
    ContactModel(
      otherUserId: 'cnt-5',
      otherUserName: 'Karan Desai',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-6',
      otherUserName: 'Sneha Patil',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-7',
      otherUserName: 'Arjun Rao',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-8',
      otherUserName: 'Meera Iyer',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-9',
      otherUserName: 'Vikram Singh',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-10',
      otherUserName: 'Isha Kapoor',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-11',
      otherUserName: 'Rahul Verma',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
    ),
    ContactModel(
      otherUserId: 'cnt-12',
      otherUserName: 'Neha Gupta',
      otherUserAvatar:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
    ),
  ];
}
