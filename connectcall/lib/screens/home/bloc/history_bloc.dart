import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/history_model.dart';
import '../../../services/firebase/history.service.dart';
import 'history_event.dart';
import 'history_state.dart';

export 'history_event.dart';
export 'history_state.dart';

/// BLoC managing call history retrieval, filtering, search, and real-time updates for HomePage.
///
/// Communicates with [HistoryService] to fetch calls from `/profile/{currentUserId}/history/`.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required HistoryService historyService,
  })  : _historyService = historyService,
        super(const HistoryState()) {
    on<HistoryFetchRequested>(_onFetchRequested);
    on<HistorySubscriptionRequested>(_onSubscriptionRequested);
    on<HistoryFilterChanged>(_onFilterChanged);
    on<HistorySearchChanged>(_onSearchChanged);
    on<HistoryCallAdded>(_onCallAdded);
  }

  final HistoryService _historyService;
  StreamSubscription? _historySubscription;

  Future<void> _onFetchRequested(
    HistoryFetchRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading, errorMessage: null));

    try {
      final history = await _historyService.getCallHistory();
      emit(state.copyWith(
        status: HistoryStatus.success,
        history: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubscriptionRequested(
    HistorySubscriptionRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading, errorMessage: null));

    await emit.forEach<HistoryModel>(
      _historyService.watchCallHistory(),
      onData: (history) => state.copyWith(
        status: HistoryStatus.success,
        history: history,
      ),
      onError: (error, _) => state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  void _onFilterChanged(
    HistoryFilterChanged event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(selectedFilter: event.filter));
  }

  void _onSearchChanged(
    HistorySearchChanged event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onCallAdded(
    HistoryCallAdded event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _historyService.addCall(event.call);
      final history = await _historyService.getCallHistory();
      emit(state.copyWith(
        status: HistoryStatus.success,
        history: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}
