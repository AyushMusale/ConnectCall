import '../../../models/call_model.dart';

/// Events for HistoryBloc managing call history state.
sealed class HistoryEvent {
  const HistoryEvent();
}

/// Triggered on init in HomePage to fetch call history from HistoryService.
class HistoryFetchRequested extends HistoryEvent {
  const HistoryFetchRequested();
}

/// Triggered to listen to real-time call history stream from HistoryService.
class HistorySubscriptionRequested extends HistoryEvent {
  const HistorySubscriptionRequested();
}

/// Triggered when the filter chip changes ('All', 'Missed', 'Incoming', 'Outgoing').
class HistoryFilterChanged extends HistoryEvent {
  const HistoryFilterChanged(this.filter);

  final String filter;
}

/// Triggered when the search query changes in the search bar.
class HistorySearchChanged extends HistoryEvent {
  const HistorySearchChanged(this.query);

  final String query;
}

/// Triggered when a new call log is recorded through HistoryService.
class HistoryCallAdded extends HistoryEvent {
  const HistoryCallAdded(this.call);

  final CallModel call;
}
