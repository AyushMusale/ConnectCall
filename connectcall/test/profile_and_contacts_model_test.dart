import 'package:connectcall/models/contacts_model.dart';
import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/screens/contacts/models/contact_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileModel Tests', () {
    test('ProfileModel supports optional avatar field', () {
      // 1. Without avatar
      const profileNoAvatar = ProfileModel(
        id: 'user_1',
        name: 'Aditi Sharma',
        email: 'aditi@example.com',
      );
      expect(profileNoAvatar.id, 'user_1');
      expect(profileNoAvatar.name, 'Aditi Sharma');
      expect(profileNoAvatar.email, 'aditi@example.com');
      expect(profileNoAvatar.avatar, isNull);

      // 2. With avatar
      const profileWithAvatar = ProfileModel(
        id: 'user_2',
        name: 'Rohan Mehta',
        email: 'rohan@example.com',
        avatar: 'https://images.example.com/rohan.jpg',
      );
      expect(profileWithAvatar.avatar, 'https://images.example.com/rohan.jpg');
    });

    test('ProfileModel fromJson parses avatar and avatarUrl', () {
      final jsonWithAvatar = {
        'id': 'user_1',
        'name': 'Aditi Sharma',
        'email': 'aditi@example.com',
        'avatar': 'https://example.com/aditi.jpg',
      };
      final p1 = ProfileModel.fromJson(jsonWithAvatar);
      expect(p1.avatar, 'https://example.com/aditi.jpg');

      final jsonWithAvatarUrl = {
        'id': 'user_2',
        'name': 'Priya Nair',
        'email': 'priya@example.com',
        'avatarUrl': 'https://example.com/priya.jpg',
      };
      final p2 = ProfileModel.fromJson(jsonWithAvatarUrl);
      expect(p2.avatar, 'https://example.com/priya.jpg');

      final jsonNoAvatar = {
        'id': 'user_3',
        'name': 'Karan Desai',
        'email': 'karan@example.com',
      };
      final p3 = ProfileModel.fromJson(jsonNoAvatar);
      expect(p3.avatar, isNull);
    });

    test('ProfileModel toJson includes avatar when present', () {
      const profile = ProfileModel(
        id: 'user_1',
        name: 'Aditi Sharma',
        email: 'aditi@example.com',
        avatar: 'https://example.com/aditi.jpg',
      );
      final json = profile.toJson();
      expect(json['id'], 'user_1');
      expect(json['name'], 'Aditi Sharma');
      expect(json['email'], 'aditi@example.com');
      expect(json['avatar'], 'https://example.com/aditi.jpg');
    });

    test('ProfileModel copyWith works with avatar', () {
      const original = ProfileModel(
        id: 'user_1',
        name: 'Aditi Sharma',
        email: 'aditi@example.com',
      );
      final updated = original.copyWith(
        avatar: 'https://example.com/aditi_new.jpg',
      );
      expect(updated.id, 'user_1');
      expect(updated.name, 'Aditi Sharma');
      expect(updated.email, 'aditi@example.com');
      expect(updated.avatar, 'https://example.com/aditi_new.jpg');
    });

    test('ProfileModel supports isOnline and lastSeen serialization', () {
      final now = DateTime(2026, 9, 12, 19, 30);
      final profile = ProfileModel(
        id: 'user_online',
        name: 'Aditi Online',
        email: 'aditi@example.com',
        isOnline: true,
        lastSeen: now,
      );
      expect(profile.isOnline, isTrue);
      expect(profile.lastSeen, now);

      final json = profile.toJson();
      expect(json['isOnline'], isTrue);
      expect(json['lastSeen'], now.toIso8601String());

      final fromJson = ProfileModel.fromJson(json);
      expect(fromJson.isOnline, isTrue);
      expect(fromJson.lastSeen, now);

      final copy = fromJson.copyWith(isOnline: false);
      expect(copy.isOnline, isFalse);
    });

    test('ContactModel supports isOnline and maps from ProfileModel', () {
      final profile = ProfileModel(
        id: 'u1',
        name: 'Aditi Sharma',
        email: 'aditi@test.com',
        isOnline: true,
      );
      final contact = ContactModel.fromProfile(profile);
      expect(contact.isOnline, isTrue);

      final json = contact.toJson();
      expect(json['isOnline'], isTrue);

      final fromJson = ContactModel.fromJson(json);
      expect(fromJson.isOnline, isTrue);
    });
  });

  group('ContactsModel Tests (Get-only)', () {
    test('fromJson parses {contacts: [...]} list of profiles', () {
      final json = {
        'contacts': [
          {
            'id': 'u1',
            'name': 'Aditi Sharma',
            'email': 'aditi@example.com',
            'avatar': 'https://example.com/aditi.jpg',
          },
          {
            'id': 'u2',
            'name': 'Rohan Mehta',
            'email': 'rohan@example.com',
          },
        ],
      };

      final contactsModel = ContactsModel.fromJson(json);

      expect(contactsModel.length, 2);
      expect(contactsModel.isNotEmpty, isTrue);
      expect(contactsModel[0].id, 'u1');
      expect(contactsModel[0].name, 'Aditi Sharma');
      expect(contactsModel[0].avatar, 'https://example.com/aditi.jpg');
      expect(contactsModel[1].id, 'u2');
      expect(contactsModel[1].name, 'Rohan Mehta');
      expect(contactsModel[1].avatar, isNull);
    });

    test('fromJson parses key-value document maps {uid: {...}}', () {
      final json = {
        'doc_1': {
          'name': 'Priya Nair',
          'email': 'priya@example.com',
          'avatar': 'https://example.com/priya.jpg',
        },
        'doc_2': {
          'id': 'doc_2_custom',
          'name': 'Karan Desai',
          'email': 'karan@example.com',
        },
      };

      final contactsModel = ContactsModel.fromJson(json);
      expect(contactsModel.length, 2);
      expect(contactsModel[0].id, 'doc_1');
      expect(contactsModel[0].name, 'Priya Nair');
      expect(contactsModel[1].id, 'doc_2_custom');
      expect(contactsModel[1].name, 'Karan Desai');
    });

    test('fromList parses List of ProfileModel maps or instances', () {
      final list = [
        {
          'id': 'u1',
          'name': 'User One',
          'email': 'one@example.com',
        },
        const ProfileModel(
          id: 'u2',
          name: 'User Two',
          email: 'two@example.com',
          avatar: 'https://example.com/2.png',
        ),
      ];

      final contactsModel = ContactsModel.fromList(list);
      expect(contactsModel.length, 2);
      expect(contactsModel[0].id, 'u1');
      expect(contactsModel[1].id, 'u2');
      expect(contactsModel[1].avatar, 'https://example.com/2.png');
    });

    test('handles empty or malformed inputs gracefully', () {
      const emptyModel = ContactsModel();
      expect(emptyModel.isEmpty, isTrue);
      expect(emptyModel.contacts, isEmpty);

      final fromEmptyMap = ContactsModel.fromJson({});
      expect(fromEmptyMap.isEmpty, isTrue);

      final fromEmptyList = ContactsModel.fromList([]);
      expect(fromEmptyList.isEmpty, isTrue);
    });

    test('Contacts typedef references ContactsModel', () {
      const Contacts c = ContactsModel(contacts: [
        ProfileModel(id: '1', name: 'Test', email: 'test@test.com'),
      ]);
      expect(c.length, 1);
    });
  });
}
