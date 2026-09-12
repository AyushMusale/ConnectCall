import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/call_model.dart';
import '../../../services/calls.service.dart';
import '../../../services/firebase/history.service.dart';
import '../../../services/firebase/session.service.dart';
import '../../../services/firebase/signaling.service.dart';
import 'call_event.dart';
import 'call_state.dart';

export 'call_event.dart';
export 'call_state.dart';

/// BLoC for managing call lifecycle:
/// - Initiating outgoing calls
/// - 30-second unanswered timeout transitioning to 'missed'
/// - Starting duration timer when accepted
/// - Ending call and recording history for both participants in `/profile/{userId}/history`
class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc({
    CallsService? callsService,
    SignalingService? signalingService,
    HistoryService? historyService,
    SessionService? sessionService,
    Duration timeoutDuration = const Duration(seconds: 30),
  })  : _callsService = callsService ?? CallsService(),
        _signalingService = signalingService ?? SignalingService(),
        _historyService = historyService ?? HistoryService(),
        _sessionService = sessionService ?? SessionService(),
        _timeoutDuration = timeoutDuration,
        super(const CallState()) {
    on<CallIncomingListenerStarted>(_onCallIncomingListenerStarted);
    on<CallStartRequested>(_onCallStartRequested);
    on<CallAccepted>(_onCallAccepted);
    on<CallIncomingReceived>(_onCallIncomingReceived);
    on<CallPickUpRequested>(_onCallPickUpRequested);
    on<CallRejectRequested>(_onCallRejectRequested);
    on<CallTimeoutMissed>(_onCallTimeoutMissed);
    on<CallTimerTicked>(_onCallTimerTicked);
    on<CallRingCountdownTicked>(_onCallRingCountdownTicked);
    on<CallEndRequested>(_onCallEndRequested);
    on<CallStatusUpdated>(_onCallStatusUpdated);
    on<CallReset>(_onCallReset);

    // Continuously listens for incoming calls via SignalingService
    add(const CallIncomingListenerStarted());
  }

  final CallsService _callsService;
  final SignalingService _signalingService;
  final HistoryService _historyService;
  final SessionService _sessionService;
  final Duration _timeoutDuration;

  Timer? _ringTimeoutTimer;
  Timer? _ringCountdownTimer;
  Timer? _durationTimer;
  StreamSubscription? _callStatusSubscription;
  StreamSubscription? _incomingCallSubscription;

  Future<void> _onCallStartRequested(
    CallStartRequested event,
    Emitter<CallState> emit,
  ) async {
    _cancelAllTimers();

    final now = DateTime.now();
    final totalTimeoutSeconds = _timeoutDuration.inSeconds;
    final initialCountdown = totalTimeoutSeconds > 0
        ? totalTimeoutSeconds
        : (_timeoutDuration.inMilliseconds > 0 ? 0 : 30);

    emit(state.copyWith(
      status: CallStateStatus.ringing,
      otherUserId: event.otherUserId,
      otherUserName: event.otherUserName,
      otherUserAvatar: event.otherUserAvatar,
      callType: event.type,
      durationSeconds: 0,
      ringRemainingSeconds: initialCountdown,
      createdAt: now,
      errorMessage: null,
    ));
    // 1. Start 30-second ring countdown and timeout
    _startRingTimeoutCountdown(totalTimeoutSeconds);

    // 2. Initiate call via CallsService
    try {
      final callId = await _callsService.startCall(
        event.otherUserId,
        type: event.type,
        isVideo: event.type == 'video',
        onCallStatusChanged: (status) {
          add(CallStatusUpdated(status));
        },
      );

      emit(state.copyWith(callId: callId));

      // 3. Fallback/Direct listener on Firestore call doc
      await _callStatusSubscription?.cancel();
      _callStatusSubscription = _signalingService.listenToCall(
        callId: callId,
        onStatusChanged: (status) {
          add(CallStatusUpdated(status));
        },
      );
    } catch (e) {
      // In offline/test mode, missing native WebRTC devices, or missing permissions,
      // maintain ringing state with a fallback callId so countdown and 30-second timeout continue.
      final localCallId = 'call_${now.millisecondsSinceEpoch}';
      emit(state.copyWith(
        callId: localCallId,
        errorMessage: e.toString(),
      ));
    }
  }

  void _startRingTimeoutCountdown(int totalSeconds) {
    _ringCountdownTimer?.cancel();
    _ringTimeoutTimer?.cancel();

    final duration = totalSeconds > 0
        ? Duration(seconds: totalSeconds)
        : (_timeoutDuration.inSeconds > 0
            ? _timeoutDuration
            : const Duration(seconds: 30));
    var remaining = duration.inSeconds;

    if (totalSeconds > 0) {
      _ringCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isClosed || (!state.isRinging && !state.isIncoming)) {
          timer.cancel();
          return;
        }

        remaining--;
        if (remaining > 0) {
          add(CallRingCountdownTicked(remaining));
        } else {
          timer.cancel();
          add(const CallRingCountdownTicked(0));
          add(const CallTimeoutMissed());
        }
      });
    }

    _ringTimeoutTimer = Timer(duration, () {
      if (!isClosed && (state.isRinging || state.isIncoming)) {
        add(const CallTimeoutMissed());
      }
    });
  }

  void _onCallRingCountdownTicked(
    CallRingCountdownTicked event,
    Emitter<CallState> emit,
  ) {
    if (state.isRinging || state.isIncoming) {
      emit(state.copyWith(ringRemainingSeconds: event.remainingSeconds));
    }
  }

  Future<void> _onCallIncomingListenerStarted(
    CallIncomingListenerStarted event,
    Emitter<CallState> emit,
  ) async {
    await _incomingCallSubscription?.cancel();
    try {
      _incomingCallSubscription = _signalingService.listenForIncomingCalls(
        onIncomingCall: (callDoc) {
          final data = callDoc.data();
          if (data == null) return;
          final callId = callDoc.id;
          final callerId = (data['callerId'] ?? '').toString();
          final callerName = (data['callerName'] ?? 'Contact').toString();
          final callerAvatar = data['callerAvatar'] as String?;
          final type = (data['type'] ?? 'audio').toString();

          add(CallIncomingReceived(
            callId: callId,
            callerId: callerId,
            callerName: callerName,
            callerAvatar: callerAvatar,
            type: type,
          ));
        },
        onError: (_) {},
      );
    } catch (_) {
      // In offline tests or when Firebase is not initialized, ignore gracefully
    }
  }

  Future<void> _onCallIncomingReceived(
    CallIncomingReceived event,
    Emitter<CallState> emit,
  ) async {
    _cancelAllTimers();

    final now = DateTime.now();
    final totalTimeoutSeconds = _timeoutDuration.inSeconds > 0
        ? _timeoutDuration.inSeconds
        : 30;

    emit(state.copyWith(
      status: CallStateStatus.incoming,
      callId: event.callId,
      otherUserId: event.callerId,
      otherUserName: event.callerName,
      otherUserAvatar: event.callerAvatar,
      callType: event.type,
      durationSeconds: 0,
      ringRemainingSeconds: totalTimeoutSeconds,
      createdAt: now,
      errorMessage: null,
    ));

    // 30 seconds timer: keep page open till 30 seconds then close (CallTimeoutMissed)
    _startRingTimeoutCountdown(totalTimeoutSeconds);

    await _callStatusSubscription?.cancel();
    try {
      _callStatusSubscription = _signalingService.listenToCall(
        callId: event.callId,
        onStatusChanged: (status) {
          add(CallStatusUpdated(status));
        },
      );
    } catch (_) {}
  }

  Future<void> _onCallPickUpRequested(
    CallPickUpRequested event,
    Emitter<CallState> emit,
  ) async {
    if (!state.isIncoming && !state.isRinging) return;

    final callId = state.callId;
    _cancelAllTimers();

    emit(state.copyWith(
      status: CallStateStatus.ongoing,
      durationSeconds: 0,
    ));

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed && state.isOngoing) {
        add(CallTimerTicked(state.durationSeconds + 1));
      } else {
        timer.cancel();
      }
    });

    if (callId != null && callId.isNotEmpty) {
      try {
        await _callsService.answerCall(
          callId,
          type: state.callType,
          isVideo: state.callType == 'video',
          onCallStatusChanged: (status) {
            add(CallStatusUpdated(status));
          },
        );
      } catch (e) {
        // Fallback for tests or missing native hardware
      }
    }
  }

  Future<void> _onCallRejectRequested(
    CallRejectRequested event,
    Emitter<CallState> emit,
  ) async {
    final callId = state.callId;
    _cancelAllTimers();

    emit(state.copyWith(
      status: CallStateStatus.rejected,
      ringRemainingSeconds: 0,
    ));

    if (callId != null && callId.isNotEmpty) {
      try {
        await _signalingService.updateCallStatus(
          callId: callId,
          status: 'rejected',
        );
      } catch (_) {}

      try {
        await _callsService.rejectCall(callId);
      } catch (_) {}
    }

    await _recordHistoryForBoth(
      callerStatus: 'missed',
      receiverStatus: 'missed',
      duration: 0,
    );
  }

  Future<void> _onCallAccepted(
    CallAccepted event,
    Emitter<CallState> emit,
  ) async {
    if (!state.isRinging && !state.isStarting && !state.isIncoming) return;

    // 1. Cancel ring countdown and timeout
    _ringTimeoutTimer?.cancel();
    _ringCountdownTimer?.cancel();

    // 2. Transition status to ongoing
    emit(state.copyWith(
      status: CallStateStatus.ongoing,
      durationSeconds: 0,
    ));

    // 3. Start 1-second call duration timer
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed && state.isOngoing) {
        add(CallTimerTicked(state.durationSeconds + 1));
      } else {
        timer.cancel();
      }
    });
  }

  void _onCallTimerTicked(
    CallTimerTicked event,
    Emitter<CallState> emit,
  ) {
    if (state.isOngoing) {
      emit(state.copyWith(durationSeconds: event.durationSeconds));
    }
  }

  Future<void> _onCallTimeoutMissed(
    CallTimeoutMissed event,
    Emitter<CallState> emit,
  ) async {
    if (!state.isRinging && !state.isIncoming) return;

    _cancelAllTimers();

    // Immediately emit missed status with 0 remaining seconds so UI responds instantaneously
    emit(state.copyWith(
      status: CallStateStatus.missed,
      ringRemainingSeconds: 0,
    ));

    final callId = state.callId;
    if (callId != null && callId.isNotEmpty) {
      try {
        await _signalingService.updateCallStatus(
          callId: callId,
          status: 'missed',
        );
      } catch (_) {}
    }

    try {
      await _callsService.endCall(status: 'missed');
    } catch (_) {}

    // Save call history with status: 'missed' and duration: 0 for BOTH users
    await _recordHistoryForBoth(
      callerStatus: 'missed',
      receiverStatus: 'missed',
      duration: 0,
    );
  }

  Future<void> _onCallEndRequested(
    CallEndRequested event,
    Emitter<CallState> emit,
  ) async {
    if (!state.isActive) return;

    final wasOngoing = state.isOngoing;
    final finalDuration = state.durationSeconds;
    final reason = event.reason ?? 'ended';

    _cancelAllTimers();

    emit(state.copyWith(
      status: reason == 'rejected'
          ? CallStateStatus.rejected
          : CallStateStatus.ended,
      ringRemainingSeconds: 0,
    ));

    final callId = state.callId;
    if (callId != null && callId.isNotEmpty) {
      try {
        await _signalingService.updateCallStatus(
          callId: callId,
          status: reason,
        );
      } catch (_) {}
    }

    try {
      await _callsService.endCall(status: reason);
    } catch (_) {}

    // Save history for BOTH users
    final callerStatus = wasOngoing ? 'outgoing' : 'missed';
    final receiverStatus = wasOngoing ? 'incoming' : 'missed';

    await _recordHistoryForBoth(
      callerStatus: callerStatus,
      receiverStatus: receiverStatus,
      duration: wasOngoing ? finalDuration : 0,
    );
  }

  Future<void> _onCallStatusUpdated(
    CallStatusUpdated event,
    Emitter<CallState> emit,
  ) async {
    final status = event.status.toLowerCase();

    if (status == 'ongoing' && (state.isRinging || state.isIncoming)) {
      add(const CallAccepted());
    } else if (status == 'missed' && (state.isRinging || state.isIncoming)) {
      add(const CallTimeoutMissed());
    } else if (status == 'rejected' && state.isActive) {
      add(const CallEndRequested(reason: 'rejected'));
    } else if (status == 'ended' && state.isActive) {
      add(const CallEndRequested(reason: 'ended'));
    }
  }

  void _onCallReset(
    CallReset event,
    Emitter<CallState> emit,
  ) {
    _cancelAllTimers();
    emit(const CallState());
  }

  Future<void>  _recordHistoryForBoth({
    required String callerStatus,
    required String receiverStatus,
    required int duration,
  }) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    // 1. Resolve caller from active Firestore profile and session
    final profile = await _sessionService.getActiveProfile();
    final user = await _sessionService.resolveCurrentUser();
    final callerId = user?.uid ?? profile?.id ?? '';
    final callerName = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : (user?.displayName?.isNotEmpty ?? false
            ? user!.displayName!
            : (user?.email?.split('@').first ?? 'Caller'));
    final callerAvatar = profile?.avatar ?? user?.photoURL;

    // 2. Resolve receiver details (already provided from contact, history, or signaling)
    final receiverId = state.otherUserId ?? '';
    final receiverName = (state.otherUserName != null && state.otherUserName!.isNotEmpty)
        ? state.otherUserName!
        : 'Contact';
    final receiverAvatar = state.otherUserAvatar;

    final callType = state.callType;
    final createdAt = state.createdAt ?? DateTime.now();

    final callerEntry = CallModel(
      callerId: callerId,
      otherUserId: receiverId,
      otherUserName: receiverName,
      otherUserAvatar: receiverAvatar,
      type: callType,
      createdAt: createdAt,
      status: callerStatus,
      duration: duration,
    );

    final receiverEntry = CallModel(
      callerId: callerId,
      otherUserId: callerId,
      otherUserName: callerName,
      otherUserAvatar: callerAvatar,
      type: callType,
      createdAt: createdAt,
      status: receiverStatus,
      duration: duration,
    );
    
    try {
      await _historyService.recordCallForBothUsers(
        callerCall: callerEntry,
        receiverCall: receiverEntry,
        callerId: callerId,
        receiverId: receiverId,
      );
    } catch (_) {}
  }

  void _cancelAllTimers() {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
    _ringCountdownTimer?.cancel();
    _ringCountdownTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _callStatusSubscription?.cancel();
    _callStatusSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelAllTimers();
    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = null;
    return super.close();
  }
}
