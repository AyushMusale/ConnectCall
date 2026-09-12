import 'call_model.dart';

/// Model representing the call history collection retrieved for display on the home page.
class HistoryModel {
  const HistoryModel({
    this.history = const [],
  });

  /// List of calls in history.
  final List<CallModel> history;

  /// Factory constructor to parse history from JSON `{'history': [...]}`.
  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['history'];
    return HistoryModel(
      history: _parseCalls(rawList),
    );
  }

  /// Factory constructor to parse history directly from a `List<dynamic>`.
  factory HistoryModel.fromList(List<dynamic> list) {
    return HistoryModel(
      history: _parseCalls(list),
    );
  }

  static List<CallModel> _parseCalls(dynamic rawList) {
    if (rawList is! List) return const [];
    return rawList
        .map((item) {
          if (item is Map<String, dynamic>) {
            return CallModel.fromJson(item);
          } else if (item is Map) {
            return CallModel.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<CallModel>()
        .toList();
  }

  /// Creates a copy of this [HistoryModel] with optional replacement fields.
  HistoryModel copyWith({
    List<CallModel>? history,
  }) {
    return HistoryModel(
      history: history ?? this.history,
    );
  }

  /// Convenience getters for filtering and checking history entries
  bool get isEmpty => history.isEmpty;
  bool get isNotEmpty => history.isNotEmpty;
  int get length => history.length;

  /// Returns all calls that were missed.
  List<CallModel> get missedCalls =>
      history.where((call) => call.isMissed).toList();

  /// Returns all calls received.
  List<CallModel> get incomingCalls =>
      history.where((call) => call.isIncoming).toList();

  /// Returns all outgoing calls made.
  List<CallModel> get outgoingCalls =>
      history.where((call) => call.isOutgoing).toList();
}
