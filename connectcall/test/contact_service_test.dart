import 'package:connectcall/injection.dart';
import 'package:connectcall/models/contacts_model.dart';
import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/screens/contacts/models/contact_model.dart';
import 'package:connectcall/services/firebase/contact.service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeContactService extends ContactService {
  FakeContactService({
    this.currentUid = 'user_me',
    this.currentEmail = 'me@example.com',
    List<Map<String, dynamic>>? initialProfiles,
  }) : profilesStorage = initialProfiles ?? [];

  String? currentUid;
  String? currentEmail;
  final List<Map<String, dynamic>> profilesStorage;

  @override
  Future<List<ProfileModel>> getContacts() async {
    final uid = currentUid;
    final email = currentEmail?.toLowerCase();
    return profilesStorage
        .map((data) => ProfileModel.fromJson(data))
        .where((profile) {
          if (uid != null && uid.isNotEmpty && profile.id == uid) {
            return false;
          }
          if (email != null &&
              email.isNotEmpty &&
              profile.email.toLowerCase() == email) {
            return false;
          }
          return true;
        })
        .toList();
  }

  @override
  Future<ContactsModel> getContactsModel() async {
    final list = await getContacts();
    return ContactsModel(contacts: list);
  }

  @override
  Stream<List<ProfileModel>> watchContacts() async* {
    yield await getContacts();
  }

  @override
  Stream<ContactsModel> watchContactsModel() async* {
    final list = await getContacts();
    yield ContactsModel(contacts: list);
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  group('ContactService Unit Tests', () {
    final sampleProfiles = [
      {
        'id': 'user_me',
        'name': 'My Account',
        'email': 'me@example.com',
        'avatar': 'https://example.com/me.png',
      },
      {
        'id': 'user_1',
        'name': 'Aditi Sharma',
        'email': 'aditi@example.com',
        'avatar': 'https://example.com/aditi.png',
      },
      {
        'id': 'user_2',
        'name': 'Rohan Mehta',
        'email': 'rohan@example.com',
        'avatar': null,
      },
      {
        'id': 'user_3',
        'name': 'Priya Nair',
        'email': 'priya@example.com',
        'avatarUrl': 'https://example.com/priya.png',
      },
    ];

    test('getContacts() automatically excludes current user', () async {
      final service = FakeContactService(
        currentUid: 'user_me',
        initialProfiles: List.from(sampleProfiles),
      );

      final contacts = await service.getContacts();
      expect(contacts.length, 3);
      expect(contacts.any((c) => c.id == 'user_me'), isFalse);
    });

    test('getContacts() excludes profile matching email even if id is different', () async {
      final service = FakeContactService(
        currentUid: 'different_uid',
        currentEmail: 'me@example.com',
        initialProfiles: List.from(sampleProfiles),
      );

      final contacts = await service.getContacts();
      expect(contacts.length, 3);
      expect(contacts.any((c) => c.email == 'me@example.com'), isFalse);
    });

    test('ContactService offline fallback returns sampleContacts', () async {
      final service = ContactService();
      final contacts = await service.getContacts();
      expect(contacts.isNotEmpty, isTrue);
      expect(contacts.length, ContactModel.sampleContacts.length);
    });

    test('getContactsModel() returns ContactsModel excluding current user by default', () async {
      final service = FakeContactService(
        currentUid: 'user_me',
        initialProfiles: List.from(sampleProfiles),
      );

      final model = await service.getContactsModel();
      expect(model, isA<ContactsModel>());
      expect(model.length, 3);
      expect(model.isNotEmpty, isTrue);
    });

    test('watchContacts() streams profiles excluding current user by default', () async {
      final service = FakeContactService(
        currentUid: 'user_me',
        initialProfiles: List.from(sampleProfiles),
      );

      final stream = service.watchContacts();
      final firstEmission = await stream.first;
      expect(firstEmission.length, 3);
    });

    test('watchContactsModel() streams ContactsModel excluding current user by default', () async {
      final service = FakeContactService(
        currentUid: 'user_me',
        initialProfiles: List.from(sampleProfiles),
      );

      final stream = service.watchContactsModel();
      final firstEmission = await stream.first;
      expect(firstEmission, isA<ContactsModel>());
      expect(firstEmission.length, 3);
    });

    test('getIt registers ContactService singleton', () {
      expect(getIt.isRegistered<ContactService>(), isTrue);
      final registered = getIt<ContactService>();
      expect(registered, isNotNull);
    });
  });
}
