/// Status of the call lifecycle managed by [CallBloc].
enum CallStateStatus {
  initial,
  starting,
  ringing,
  incoming,
  ongoing,
  missed,
  rejected,
  ended,
  failure,
}

/// State representation of an active, incoming, or finished call.
class CallState {
  const CallState({
    this.status = CallStateStatus.initial,
    this.callId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.callType = 'audio',
    this.durationSeconds = 0,
    this.ringRemainingSeconds = 30,
    this.createdAt,
    this.errorMessage,
  });

  /// Current status of the call.
  final CallStateStatus status;

  /// Firestore call document ID.
  final String? callId;

  /// User ID of the remote participant.
  final String? otherUserId;

  /// Display name of the remote participant.
  final String? otherUserName;

  /// Avatar URL of the remote participant.
  final String? otherUserAvatar;

  /// Type of call: 'audio' or 'video'.
  final String callType;

  /// Call duration in seconds (active while [status] is [CallStateStatus.ongoing]).
  final int durationSeconds;

  /// Countdown in seconds remaining before a ringing call is marked as missed (default 30s).
  final int ringRemainingSeconds;

  /// Timestamp when the call was initiated.
  final DateTime? createdAt;

  /// Error description if a failure occurred.
  final String? errorMessage;

  // Convenience getters
  bool get isInitial => status == CallStateStatus.initial;
  bool get isStarting => status == CallStateStatus.starting;
  bool get isRinging => status == CallStateStatus.ringing;
  bool get isIncoming => status == CallStateStatus.incoming;
  bool get isOngoing => status == CallStateStatus.ongoing;
  bool get isMissed => status == CallStateStatus.missed;
  bool get isRejected => status == CallStateStatus.rejected;
  bool get isEnded => status == CallStateStatus.ended;
  bool get isFailure => status == CallStateStatus.failure;
  bool get isActive => isRinging || isIncoming || isOngoing;

  /// Formatted duration string formatted as `mm:ss` (e.g. `01:23`).
  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formatted ring countdown string formatted as `mm:ss` (e.g. `00:30`).
  String get formattedRingRemaining {
    final minutes = (ringRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (ringRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  CallState copyWith({
    CallStateStatus? status,
    String? callId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? callType,
    int? durationSeconds,
    int? ringRemainingSeconds,
    DateTime? createdAt,
    String? errorMessage,
  }) {
    return CallState(
      status: status ?? this.status,
      callId: callId ?? this.callId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      callType: callType ?? this.callType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      ringRemainingSeconds: ringRemainingSeconds ?? this.ringRemainingSeconds,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallState &&
        other.status == status &&
        other.callId == callId &&
        other.otherUserId == otherUserId &&
        other.otherUserName == otherUserName &&
        other.otherUserAvatar == otherUserAvatar &&
        other.callType == callType &&
        other.durationSeconds == durationSeconds &&
        other.ringRemainingSeconds == ringRemainingSeconds &&
        other.createdAt == createdAt &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        callId,
        otherUserId,
        otherUserName,
        otherUserAvatar,
        callType,
        durationSeconds,
        ringRemainingSeconds,
        createdAt,
        errorMessage,
      );

  @override
  String toString() {
    return 'CallState(status: $status, callId: $callId, otherUserId: $otherUserId, '
        'otherUserName: $otherUserName, callType: $callType, duration: $durationSeconds, '
        'ringRemaining: $ringRemainingSeconds, error: $errorMessage)';
  }
}
