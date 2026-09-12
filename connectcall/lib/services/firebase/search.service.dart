import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/profile_model.dart';

/// Service for searching user profiles in Cloud Firestore using prefix matching.
class SearchService {
  SearchService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// collection using the `namelower` field in a single query.
  Future<List<ProfileModel>> search(String query, {int limit = 20}) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return const [];

    final endPrefix = '$cleanQuery\uf8ff';

    final snapshot = await _db
        .collection('profile')
        .where('namelower', isGreaterThanOrEqualTo: cleanQuery)
        .where('namelower', isLessThan: endPrefix)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ProfileModel.fromJson({
        'id': doc.id,
        ...data,
      });
    }).toList();
  }
}
