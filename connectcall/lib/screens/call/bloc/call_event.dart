/// Base class for all events processed by [CallBloc].
sealed class CallEvent {
  const CallEvent();
}

/// Dispatched to initiate an outgoing call to [otherUserId].
class CallStartRequested extends CallEvent {
  const CallStartRequested({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.type = 'audio',
  });

  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String type;
}

/// Dispatched when the remote receiver accepts the call.
class CallAccepted extends CallEvent {
  const CallAccepted();
}

/// Dispatched when 30 seconds elapse without the callee answering.
class CallTimeoutMissed extends CallEvent {
  const CallTimeoutMissed();
}

/// Dispatched every second during an ongoing call to update elapsed duration.
class CallTimerTicked extends CallEvent {
  const CallTimerTicked(this.durationSeconds);

  final int durationSeconds;
}

/// Dispatched every second while ringing to update the 30-second countdown.
class CallRingCountdownTicked extends CallEvent {
  const CallRingCountdownTicked(this.remainingSeconds);

  final int remainingSeconds;
}

/// Dispatched to end the current call (by either party).
class CallEndRequested extends CallEvent {
  const CallEndRequested({this.reason});

  final String? reason;
}

/// Dispatched when the call status changes in Firestore ('ringing', 'ongoing', 'ended', 'rejected', 'missed').
class CallStatusUpdated extends CallEvent {
  const CallStatusUpdated(this.status);

  final String status;
}

/// Dispatched to continuously listen for incoming calls via [SignalingService].
class CallIncomingListenerStarted extends CallEvent {
  const CallIncomingListenerStarted();
}

/// Alias for [CallIncomingListenerStarted] matching various naming conventions.
typedef IncomingCallListenerEvent = CallIncomingListenerStarted;
typedef CallIncomingListener = CallIncomingListenerStarted;

/// Dispatched when an incoming call is received for the current user.
class CallIncomingReceived extends CallEvent {
  const CallIncomingReceived({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    this.type = 'audio',
  });

  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String type;
}

/// Dispatched by the receiver to pick up / answer an incoming call.
class CallPickUpRequested extends CallEvent {
  const CallPickUpRequested();
}

/// Dispatched by the receiver to reject / end an incoming call.
class CallRejectRequested extends CallEvent {
  const CallRejectRequested();
}

/// Resets the CallBloc state back to initial.
class CallReset extends CallEvent {
  const CallReset();
}
