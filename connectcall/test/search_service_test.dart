import 'package:connectcall/injection.dart';
import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/services/firebase/search.service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSearchService extends SearchService {
  FakeSearchService(this.storedProfiles);

  final List<Map<String, dynamic>> storedProfiles;

  @override
  Future<List<ProfileModel>> search(String query, {int limit = 20}) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return const [];

    final endPrefix = '$cleanQuery\uf8ff';

    // Simulate Firestore prefix range query:
    // namelower >= cleanQuery AND namelower < endPrefix
    final matches = storedProfiles.where((data) {
      final nameLower = (data['namelower'] as String? ?? '').toLowerCase();
      final isGreaterOrEqual = nameLower.compareTo(cleanQuery) >= 0;
      final isLessThan = nameLower.compareTo(endPrefix) < 0;
      return isGreaterOrEqual && isLessThan;
    }).take(limit);

    return matches.map((data) {
      return ProfileModel.fromJson({
        'id': data['id'] as String,
        'name': data['name'] as String,
        'email': data['email'] as String,
      });
    }).toList();
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  group('SearchService Prefix Match Tests', () {
    const sampleDb = [
      {
        'id': 'u1',
        'name': 'Tony Stark',
        'namelower': 'tony stark',
        'email': 'tony@stark.com',
      },
      {
        'id': 'u2',
        'name': 'Tony Montana',
        'namelower': 'tony montana',
        'email': 'scarface@miami.com',
      },
      {
        'id': 'u3',
        'name': 'Thor Odinson',
        'namelower': 'thor odinson',
        'email': 'thor@asgard.gov',
      },
      {
        'id': 'u4',
        'name': 'Steve Rogers',
        'namelower': 'steve rogers',
        'email': 'cap@avengers.org',
      },
    ];

    test('Empty or whitespace query immediately returns empty list', () async {
      final service = FakeSearchService(sampleDb);

      expect(await service.search(''), isEmpty);
      expect(await service.search('   '), isEmpty);
    });

    test('Searching "tony" matches "Tony Stark" and "Tony Montana"', () async {
      final service = FakeSearchService(sampleDb);

      final results = await service.search('tony');

      expect(results.length, equals(2));
      expect(results.map((p) => p.name), containsAll(['Tony Stark', 'Tony Montana']));
    });

    test('Searching "TONY" is case-insensitive', () async {
      final service = FakeSearchService(sampleDb);

      final results = await service.search('TONY ');

      expect(results.length, equals(2));
      expect(results.any((p) => p.name == 'Tony Stark'), isTrue);
    });

    test('Searching "tho" matches "Thor Odinson"', () async {
      final service = FakeSearchService(sampleDb);

      final results = await service.search('tho');

      expect(results.length, equals(1));
      expect(results.first.name, equals('Thor Odinson'));
      expect(results.first.id, equals('u3'));
    });

    test('Non-matching prefix returns empty list', () async {
      final service = FakeSearchService(sampleDb);

      final results = await service.search('bruce');

      expect(results, isEmpty);
    });

    test('Search query respects limit', () async {
      final service = FakeSearchService(sampleDb);

      final results = await service.search('tony', limit: 1);

      expect(results.length, equals(1));
    });

    test('Base SearchService with empty query returns empty list', () async {
      final realService = SearchService();
      // An empty query returns early without calling firestore
      final results = await realService.search('');
      expect(results, isEmpty);
    });

    test('SearchService is registered and resolvable via GetIt', () {
      expect(getIt.isRegistered<SearchService>(), isTrue);
      expect(searchService, isA<SearchService>());
    });
  });
}
