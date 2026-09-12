import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'firebase/signaling.service.dart';
import 'webRTC.service.dart';

/// Service orchestrating WebRTC peer connections and signaling for calls.
class CallsService {
  CallsService({
    WebRTCService? webRTCService,
    SignalingService? signalingService,
  })  : _webRTCService = webRTCService ?? WebRTCService(),
        _signalingService = signalingService ?? SignalingService();

  final WebRTCService _webRTCService;
  final SignalingService _signalingService;

  String? _currentCallId;
  MediaStream? _remoteStream;
  StreamSubscription<dynamic>? _callSubscription;
  StreamSubscription<dynamic>? _candidatesSubscription;
  StreamSubscription<dynamic>? _incomingCallsSubscription;

  /// Returns the continuous incoming calls stream subscription if active.
  StreamSubscription<dynamic>? get incomingCallsSubscription =>
      _incomingCallsSubscription;

  /// Returns the current active call document ID if any.
  String? get currentCallId => _currentCallId;

  /// Returns the local media stream from [WebRTCService].
  MediaStream? get localStream => _webRTCService.localStream;

  /// Returns the remote media stream received from the peer.
  MediaStream? get remoteStream => _remoteStream;

  /// Returns the active [RTCPeerConnection].
  RTCPeerConnection? get peerConnection => _webRTCService.peerConnection;

  Future<String> startCall(
    String otherUserId, {
    String type = 'audio',
    bool isVideo = false,
    void Function(MediaStream remoteStream)? onRemoteStream,
    void Function(String status)? onCallStatusChanged,
  }) async {
    try {
      final callType = (isVideo || type == 'video') ? 'video' : 'audio';

      // 1. Create call document & 2. Get callId
      final callId = await _signalingService.createCall(
        receiverId: otherUserId,
        type: callType,
      );
      _currentCallId = callId;

      // 3. Create PeerConnection
      final pc = await _webRTCService.createPeerConnectionOnly();

      // Remote stream listeners
      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
          onRemoteStream?.call(event.streams.first);
        }
      };
      pc.onAddStream = (MediaStream stream) {
        _remoteStream = stream;
        onRemoteStream?.call(stream);
      };

      // 4. Setup ICE listener
      _webRTCService.onIceCandidate(pc, (candidate) {
        _signalingService.sendCandidate(
          callId: callId,
          candidate: candidate,
          isCaller: true,
        );
      });

      // 5. getMedia + addTrack
      if (callType == 'video') {
        await _webRTCService.addAudioAndVideoLocalStream(pc);
      } else {
        await _webRTCService.addAudioOnlyLocalStream(pc);
      }

      // 6. Create offer
      final offer = await _webRTCService.createOffer(pc);

      // 7. Send offer to calls/{callId}
      await _signalingService.sendOffer(
        callId: callId,
        offer: offer,
      );

      // Listen for callee's remote answer and call state changes
      _callSubscription = _signalingService.listenToCall(
        callId: callId,
        onAnswer: (answer) async {
          await _webRTCService.setRemoteDescription(pc, answer);
        },
        onStatusChanged: (status) async {
          onCallStatusChanged?.call(status);
          if (status == 'ongoing') {
            // Once the call status changes to ongoing, establish the connection between both users
            try {
              final currentRemote = await pc.getRemoteDescription();
              if (currentRemote == null) {
                final doc = await _signalingService.getCall(callId);
                final data = doc.data();
                if (data != null && data['answer'] is Map) {
                  final answerMap = data['answer'] as Map;
                  final answer = RTCSessionDescription(
                    answerMap['sdp'] as String?,
                    answerMap['type'] as String?,
                  );
                  await _webRTCService.setRemoteDescription(pc, answer);
                }
              }
            } catch (_) {}
          } else if (status == 'ended' || status == 'rejected') {
            await endCall();
          }
        },
      );

      // Listen for callee's remote ICE candidates
      _candidatesSubscription = _signalingService.listenForCandidates(
        callId: callId,
        isCaller: true,
        onCandidate: (candidate) async {
          await _webRTCService.addCandidate(pc, candidate);
        },
      );

      return callId;
    } catch (e) {
      await endCall();
      rethrow;
    }
  }

  /// Accepts an incoming call by [callId].
  ///
  /// Orchestrates WebRTC peer connection creation, attaches local audio/video media tracks,
  /// processes the caller's SDP offer, creates and sends an SDP answer to Firestore,
  /// and listens for caller's remote ICE candidates and call status updates.
  Future<void> acceptCall(
    String callId, {
    RTCSessionDescription? offer,
    String type = 'audio',
    bool isVideo = false,
    void Function(MediaStream remoteStream)? onRemoteStream,
    void Function(String status)? onCallStatusChanged,
  }) async {
    try {
      if (_currentCallId != null && _currentCallId != callId) {
        await endCall();
      }
      _currentCallId = callId;

      var callType = (isVideo || type == 'video') ? 'video' : 'audio';

      // 1. Create PeerConnection
      final pc = await _webRTCService.createPeerConnectionOnly();

      // Remote stream listeners
      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
          onRemoteStream?.call(event.streams.first);
        }
      };
      pc.onAddStream = (MediaStream stream) {
        _remoteStream = stream;
        onRemoteStream?.call(stream);
      };

      // 2. Setup ICE listener for callee (isCaller: false -> receiverCandidates)
      _webRTCService.onIceCandidate(pc, (candidate) {
        _signalingService.sendCandidate(
          callId: callId,
          candidate: candidate,
          isCaller: false,
        );
      });

      // 3. Check if call type or offer is already in the call document if not provided
      RTCSessionDescription? incomingOffer = offer;
      if (incomingOffer == null || (!isVideo && type == 'audio')) {
        try {
          final doc = await _signalingService.getCall(callId);
          final data = doc.data();
          if (data != null) {
            if (incomingOffer == null && data['offer'] is Map) {
              final offerData = data['offer'] as Map;
              incomingOffer = RTCSessionDescription(
                offerData['sdp'] as String?,
                offerData['type'] as String?,
              );
            }
            if (!isVideo && type == 'audio' && data['type'] == 'video') {
              callType = 'video';
            }
          }
        } catch (_) {
          // If offline or Firestore call doc fetch fails, continue with passed values
        }
      }

      // 4. getMedia + addTrack
      if (callType == 'video') {
        await _webRTCService.addAudioAndVideoLocalStream(pc);
      } else {
        await _webRTCService.addAudioOnlyLocalStream(pc);
      }

      // 5. Helper to set remote offer, create answer, and send answer
      bool answerSent = false;
      Future<void> handleOffer(RTCSessionDescription remoteOffer) async {
        if (answerSent) return;
        answerSent = true;
        await _webRTCService.setRemoteDescription(pc, remoteOffer);
        final answer = await _webRTCService.createAnswer(pc);
        await _signalingService.sendAnswer(
          callId: callId,
          answer: answer,
          status: 'ongoing',
        );
      }

      // If offer is available immediately, process it
      if (incomingOffer != null) {
        await handleOffer(incomingOffer);
      }

      // 6. Listen to call updates (for remote offer if not yet available, and status changes)
      _callSubscription = _signalingService.listenToCall(
        callId: callId,
        onOffer: (remoteOffer) async {
          await handleOffer(remoteOffer);
        },
        onStatusChanged: (status) {
          onCallStatusChanged?.call(status);
          if (status == 'ended' || status == 'rejected') {
            endCall();
          }
        },
      );

      // 7. Listen for caller's remote ICE candidates (isCaller: false -> callerCandidates)
      _candidatesSubscription = _signalingService.listenForCandidates(
        callId: callId,
        isCaller: false,
        onCandidate: (candidate) async {
          await _webRTCService.addCandidate(pc, candidate);
        },
      );
    } catch (e) {
      await endCall();
      rethrow;
    }
  }

  /// Convenience alias for [acceptCall].
  Future<void> answerCall(
    String callId, {
    RTCSessionDescription? offer,
    String type = 'audio',
    bool isVideo = false,
    void Function(MediaStream remoteStream)? onRemoteStream,
    void Function(String status)? onCallStatusChanged,
  }) =>
      acceptCall(
        callId,
        offer: offer,
        type: type,
        isVideo: isVideo,
        onRemoteStream: onRemoteStream,
        onCallStatusChanged: onCallStatusChanged,
      );

  /// Rejects an incoming call by updating Firestore status to 'rejected' and cleaning up.
  Future<void> rejectCall(String callId) async {
    try {
      await _signalingService.updateCallStatus(
        callId: callId,
        status: 'rejected',
      );
    } finally {
      if (_currentCallId == callId) {
        await endCall(status: 'rejected');
      }
    }
  }

  /// Ends the active call, notifies Firestore, cancels listeners, and disposes the WebRTC stream.
  Future<void> endCall({String status = 'ended'}) async {
    try {
      final callId = _currentCallId;
      if (callId != null && callId.isNotEmpty) {
        await _signalingService.updateCallStatus(
          callId: callId,
          status: status,
        );
      }
    } catch (_) {
      // Avoid failing cleanup if call was already dismissed or network dropped
    } finally {
      await _callSubscription?.cancel();
      _callSubscription = null;

      await _candidatesSubscription?.cancel();
      _candidatesSubscription = null;

      await _webRTCService.dispose();

      _remoteStream = null;
      _currentCallId = null;
    }
  }

  /// Continuously checks and listens for incoming calls via [SignalingService].
  StreamSubscription<dynamic>? listenForIncomingCalls({
    required void Function(Map<String, dynamic> data, String callId)
        onIncomingCall,
    void Function(Object error)? onError,
  }) {
    _incomingCallsSubscription?.cancel();
    try {
      _incomingCallsSubscription = _signalingService.listenForIncomingCalls(
        onIncomingCall: (callDoc) {
          final data = callDoc.data();
          if (data != null) {
            onIncomingCall(data, callDoc.id);
          }
        },
        onError: onError,
      );
    } catch (e) {
      onError?.call(e);
    }
    return _incomingCallsSubscription;
  }

  /// Cancels the incoming call listener subscription.
  Future<void> cancelIncomingCallsListener() async {
    await _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
  }
}
