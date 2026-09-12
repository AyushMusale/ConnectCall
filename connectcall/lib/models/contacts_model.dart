import 'profile_model.dart';

/// Model representing a list of user contacts/profiles.
///
/// This is a get-only model containing only [fromJson] (no toJson),
/// holding a [List<ProfileModel>].
class ContactsModel {
  const ContactsModel({
    this.contacts = const [],
  });

  /// List of profiles in contacts.
  final List<ProfileModel> contacts;

  /// Factory constructor to parse contacts from JSON map.
  ///
  /// Handles both `{'contacts': [...]}` format and key-value document maps
  /// `{uid: {'name': '...', 'email': '...'}}`.
  factory ContactsModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['contacts'] ?? json['profiles'] ?? json['data'];
    if (rawList is List) {
      return ContactsModel(
        contacts: _parseProfiles(rawList),
      );
    }

    // Parse map of documents if passed directly
    final parsed = <ProfileModel>[];
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        parsed.add(ProfileModel.fromJson({
          if (!value.containsKey('id')) 'id': entry.key,
          ...value,
        }));
      } else if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        parsed.add(ProfileModel.fromJson({
          if (!map.containsKey('id')) 'id': entry.key,
          ...map,
        }));
      }
    }

    return ContactsModel(contacts: parsed);
  }

  /// Factory constructor to parse contacts directly from a `List<dynamic>`.
  factory ContactsModel.fromList(List<dynamic> list) {
    return ContactsModel(
      contacts: _parseProfiles(list),
    );
  }

  static List<ProfileModel> _parseProfiles(dynamic rawList) {
    if (rawList is! List) return const [];
    return rawList
        .map((item) {
          if (item is ProfileModel) {
            return item;
          } else if (item is Map<String, dynamic>) {
            return ProfileModel.fromJson(item);
          } else if (item is Map) {
            return ProfileModel.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<ProfileModel>()
        .toList();
  }

  /// Creates a copy of this [ContactsModel] with optional replacement fields.
  ContactsModel copyWith({
    List<ProfileModel>? contacts,
  }) {
    return ContactsModel(
      contacts: contacts ?? this.contacts,
    );
  }

  /// Convenience getters
  bool get isEmpty => contacts.isEmpty;
  bool get isNotEmpty => contacts.isNotEmpty;
  int get length => contacts.length;
  ProfileModel operator [](int index) => contacts[index];

  @override
  String toString() => 'ContactsModel(contacts: $contacts)';
}

/// Alias for [ContactsModel].
typedef Contacts = ContactsModel;
