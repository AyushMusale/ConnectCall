import 'package:connectcall/injection.dart';
import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/services/firebase/profile.service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfileService extends ProfileService {
  FakeProfileService({
    this.currentUid = 'user_me',
    this.currentEmail = 'ayush.sharma@example.com',
    this.initialName = 'Ayush Sharma',
    this.initialAvatar,
  }) {
    _profile = ProfileModel(
      id: currentUid ?? 'user_me',
      name: initialName,
      email: currentEmail ?? 'ayush.sharma@example.com',
      avatar: initialAvatar,
    );
  }

  String? currentUid;
  String? currentEmail;
  String initialName;
  String? initialAvatar;

  ProfileModel? _profile;
  bool signedOut = false;

  @override
  Future<ProfileModel?> getProfile() async {
    return _profile;
  }

  @override
  Stream<ProfileModel?> watchProfile() async* {
    yield _profile;
  }

  @override
  Future<ProfileModel> updateName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(newName, 'name', 'Name cannot be empty.');
    }
    if (currentUid == null) {
      throw StateError('No authenticated user found to update profile.');
    }

    _profile = _profile?.copyWith(name: trimmed) ??
        ProfileModel(
          id: currentUid!,
          name: trimmed,
          email: currentEmail ?? '',
          avatar: initialAvatar,
        );
    return _profile!;
  }

  @override
  Future<ProfileModel> updateAvatar(String avatarUrl) async {
    final trimmed = avatarUrl.trim();
    if (currentUid == null) {
      throw StateError('No authenticated user found to update avatar.');
    }

    _profile = _profile?.copyWith(avatar: trimmed) ??
        ProfileModel(
          id: currentUid!,
          name: _profile?.name ?? 'User',
          email: currentEmail ?? '',
          avatar: trimmed,
        );
    return _profile!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    _profile = null;
    currentUid = null;
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  group('ProfileService Unit Tests', () {
    test('getProfile() returns active profile details', () async {
      final service = FakeProfileService(
        currentUid: 'usr-456',
        currentEmail: 'ayush.sharma@example.com',
        initialName: 'Ayush Sharma',
        initialAvatar: 'https://example.com/avatar.jpg',
      );

      final profile = await service.getProfile();
      expect(profile, isNotNull);
      expect(profile!.id, equals('usr-456'));
      expect(profile.name, equals('Ayush Sharma'));
      expect(profile.email, equals('ayush.sharma@example.com'));
      expect(profile.avatar, equals('https://example.com/avatar.jpg'));
    });

    test('updateName() updates and returns updated profile', () async {
      final service = FakeProfileService(initialName: 'Ayush Sharma');

      final updated = await service.updateName('Ayush M. Sharma');
      expect(updated.name, equals('Ayush M. Sharma'));

      final current = await service.getProfile();
      expect(current?.name, equals('Ayush M. Sharma'));
    });

    test('updateName() throws ArgumentError on empty or whitespace name', () async {
      final service = FakeProfileService();

      expect(
        () => service.updateName(''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => service.updateName('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateAvatar() updates avatar URL', () async {
      final service = FakeProfileService();

      final updated = await service.updateAvatar('https://images.com/new.png');
      expect(updated.avatar, equals('https://images.com/new.png'));

      final current = await service.getProfile();
      expect(current?.avatar, equals('https://images.com/new.png'));
    });

    test('watchProfile() yields profile stream', () async {
      final service = FakeProfileService(initialName: 'Ayush Sharma');

      final stream = service.watchProfile();
      final emission = await stream.first;
      expect(emission?.name, equals('Ayush Sharma'));
    });

    test('signOut() sets signedOut flag and clears profile', () async {
      final service = FakeProfileService();

      await service.signOut();
      expect(service.signedOut, isTrue);

      final profile = await service.getProfile();
      expect(profile, isNull);
    });

    test('getIt registers and resolves ProfileService', () {
      expect(getIt.isRegistered<ProfileService>(), isTrue);
      expect(profileService, isNotNull);
    });

    test('Default ProfileService handles uninitialized Firebase gracefully', () async {
      final defaultService = ProfileService();
      // Should not throw unhandled exceptions
      expect(defaultService.currentUser, isNull);
      final profile = await defaultService.getProfile();
      expect(profile, isNull);
    });
  });
}
