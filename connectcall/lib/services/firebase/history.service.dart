
import 'home.service.dart';

export 'home.service.dart';

/// Service for managing and retrieving user call history from Cloud Firestore.
///
/// Extends [HomeService] to provide dedicated access to call history stored at
/// `/profile/{currentUserId}/history/`.
class HistoryService extends HomeService {
  HistoryService({
    super.firebaseAuth,
    super.firestore,
  });

  /// Factory constructor to create a [HistoryService] wrapping an existing [HomeService].
  factory HistoryService.fromHomeService(HomeService homeService) {
    return HistoryService(
      firebaseAuth: homeService.firebaseAuth,
      firestore: homeService.firestore,
    );
  }
}
