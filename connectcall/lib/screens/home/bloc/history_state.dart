import '../../../models/call_model.dart';
import '../../../models/history_model.dart';
import '../models/call_log_model.dart';

enum HistoryStatus { initial, loading, success, failure }

/// State representing call history data for HomePage retrieved via HistoryService.
class HistoryState {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.history = const HistoryModel(),
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.errorMessage,
  });

  final HistoryStatus status;
  final HistoryModel history;
  final String selectedFilter;
  final String searchQuery;
  final String? errorMessage;

  bool get isInitial => status == HistoryStatus.initial;
  bool get isLoading => status == HistoryStatus.loading;
  bool get isSuccess => status == HistoryStatus.success;
  bool get isFailure => status == HistoryStatus.failure;

  List<CallModel> get calls => history.history;

  /// Returns call models filtered by [selectedFilter] and [searchQuery].
  List<CallModel> get filteredCalls {
    final query = searchQuery.trim().toLowerCase();
    return calls.where((call) {
      final matchesQuery =
          query.isEmpty ||
          call.otherUserName.toLowerCase().contains(query) ||
          call.timeSubtitle.toLowerCase().contains(query);

      final matchesFilter = switch (selectedFilter) {
        'Missed' => call.isMissed,
        'Incoming' => call.isIncoming,
        'Outgoing' => call.isOutgoing,
        'Ended' => call.isEnded,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  /// Returns filtered calls converted into [CallLogModel] ready for UI list display.
  List<CallLogModel> get filteredCallLogs {
    return filteredCalls.map(CallLogModel.fromCallModel).toList();
  }

  HistoryState copyWith({
    HistoryStatus? status,
    HistoryModel? history,
    String? selectedFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      history: history ?? this.history,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'HistoryState(status: $status, calls: ${calls.length}, filter: $selectedFilter, query: "$searchQuery", error: $errorMessage)';
}
