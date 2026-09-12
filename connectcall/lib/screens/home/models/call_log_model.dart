import '../../../models/call_model.dart';

enum CallType {
  outgoing,
  incoming,
  missed,
}

enum CallMediaType {
  audio,
  video,
}

class CallLogModel {
  const CallLogModel({
    required this.name,
    required this.callType,
    required this.timeSubtitle,
    required this.date,
    required this.time,
    required this.mediaType,
    this.avatarUrl,
    this.callModel,
    this.callerId,
    this.isOnline = false,
  });

  final String name;
  final CallType callType;
  final String timeSubtitle;
  final String date;
  final String time;
  final CallMediaType mediaType;
  final String? avatarUrl;
  final CallModel? callModel;
  final String? callerId;
  final bool isOnline;

  /// Creates a [CallLogModel] for UI display from a domain [CallModel].
  factory CallLogModel.fromCallModel(CallModel call) {
    final callType = call.isMissed
        ? CallType.missed
        : (call.isOutgoing ? CallType.outgoing : CallType.incoming);
    final mediaType =
        call.isVideo ? CallMediaType.video : CallMediaType.audio;
    return CallLogModel(
      name: call.otherUserName,
      callType: callType,
      timeSubtitle: call.timeSubtitle,
      date: call.formattedDate,
      time: call.formattedTime,
      mediaType: mediaType,
      avatarUrl: call.otherUserAvatar,
      callModel: call,
      callerId: call.callerId,
      isOnline: call.isOnline,
    );
  }

  CallLogModel copyWith({
    String? name,
    CallType? callType,
    String? timeSubtitle,
    String? date,
    String? time,
    CallMediaType? mediaType,
    String? avatarUrl,
    CallModel? callModel,
    String? callerId,
    bool? isOnline,
  }) {
    return CallLogModel(
      name: name ?? this.name,
      callType: callType ?? this.callType,
      timeSubtitle: timeSubtitle ?? this.timeSubtitle,
      date: date ?? this.date,
      time: time ?? this.time,
      mediaType: mediaType ?? this.mediaType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      callModel: callModel ?? this.callModel,
      callerId: callerId ?? this.callerId,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  static const List<CallLogModel> sampleCalls = [
    CallLogModel(
      name: 'Aditi Sharma',
      callType: CallType.outgoing,
      timeSubtitle: 'Outgoing · 12:34',
      date: 'Today',
      time: '5:45 PM',
      mediaType: CallMediaType.audio,
      avatarUrl: '',
      isOnline: true,
    ),
    CallLogModel(
      name: 'Rohan Mehta',
      callType: CallType.missed,
      timeSubtitle: 'Missed call',
      date: 'Today',
      time: '3:12 PM',
      mediaType: CallMediaType.audio,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      isOnline: false,
    ),
    CallLogModel(
      name: 'Priya Nair',
      callType: CallType.incoming,
      timeSubtitle: 'Incoming · 08:21',
      date: 'Today',
      time: '11:03 AM',
      mediaType: CallMediaType.video,
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      isOnline: true,
    ),
    CallLogModel(
      name: 'College Buddies',
      callType: CallType.outgoing,
      timeSubtitle: 'Outgoing · 26:14',
      date: 'Yesterday',
      time: '8:47 PM',
      mediaType: CallMediaType.video,
      avatarUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=150',
      isOnline: false,
    ),
    CallLogModel(
      name: 'Karan Desai',
      callType: CallType.incoming,
      timeSubtitle: 'Incoming · 03:15',
      date: 'Yesterday',
      time: '6:21 PM',
      mediaType: CallMediaType.audio,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      isOnline: true,
    ),
    CallLogModel(
      name: 'Sneha Patil',
      callType: CallType.missed,
      timeSubtitle: 'Missed call',
      date: 'Mon, 8 Sep',
      time: '9:14 PM',
      mediaType: CallMediaType.audio,
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      isOnline: false,
    ),
    CallLogModel(
      name: 'Arjun Rao',
      callType: CallType.outgoing,
      timeSubtitle: 'Outgoing · 14:08',
      date: 'Mon, 8 Sep',
      time: '4:32 PM',
      mediaType: CallMediaType.video,
      avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
      isOnline: true,
    ),
    CallLogModel(
      name: 'Meera Iyer',
      callType: CallType.incoming,
      timeSubtitle: 'Incoming · 05:27',
      date: 'Sun, 7 Sep',
      time: '7:11 PM',
      mediaType: CallMediaType.audio,
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      isOnline: false,
    ),
    CallLogModel(
      name: 'Vikram Singh',
      callType: CallType.outgoing,
      timeSubtitle: 'Outgoing · 02:16',
      date: 'Sun, 7 Sep',
      time: '1:05 PM',
      mediaType: CallMediaType.audio,
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150',
      isOnline: true,
    ),
  ];
}
