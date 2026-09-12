/// Model representing an individual call log entry in ConnectCall.
class CallModel {
  const CallModel({
    this.id,
    this.callerId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.type,
    required this.createdAt,
    required this.status,
    this.duration,
  });

  /// Optional Firestore document ID.
  final String? id;

  /// The unique identifier of the user who initiated the call.
  final String? callerId;

  /// The unique identifier of the other participant in the call.
  final String otherUserId;

  /// The display name of the other participant.
  final String otherUserName;

  /// Avatar URL or photo of the other participant, if available.
  final String? otherUserAvatar;

  /// Type of call: 'video' or 'audio'.
  final String type;

  /// Timestamp when the call was initiated or logged.
  final DateTime createdAt;

  /// Call status: 'incoming', 'outgoing', or 'missed'.
  final String status;

  /// Duration of the call in seconds (null or 0 for missed calls).
  final int? duration;

  /// Factory constructor to create a [CallModel] from a JSON map.
  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as String?,
      callerId: json['callerId'] as String?,
      otherUserId: (json['otherUserId'] ?? '').toString(),
      otherUserName: (json['otherUserName'] ?? '').toString(),
      otherUserAvatar: json['otherUserAvatar'] as String?,
      type: (json['type'] ?? 'audio').toString(),
      createdAt: _parseDateTime(json['createdAt']),
      status: (json['status'] ?? 'incoming').toString(),
      duration: _parseDuration(json['duration']),
    );
  }

  /// Converts the [CallModel] into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (callerId != null) 'callerId': callerId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'duration': duration,
    };
  }

  /// Creates a copy of this [CallModel] with optional replacement values.
  CallModel copyWith({
    String? id,
    String? callerId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? type,
    DateTime? createdAt,
    String? status,
    int? duration,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      duration: duration ?? this.duration,
    );
  }

  // --- Convenience Getters for Home Page Display & Logic ---

  /// Whether this is a video call.
  bool get isVideo => type.toLowerCase() == 'video';

  /// Whether this is an audio call.
  bool get isAudio => type.toLowerCase() == 'audio';

  /// Whether this is an incoming call.
  bool get isIncoming => status.toLowerCase() == 'incoming';

  /// Whether this is an outgoing call.
  bool get isOutgoing => status.toLowerCase() == 'outgoing';

  /// Whether this call was missed.
  bool get isMissed => status.toLowerCase() == 'missed';

   bool get isEnded => status.toLowerCase() == 'ended';

  /// Formatted duration string as `mm:ss` (e.g. `12:34`).
  String get formattedDuration {
    if (duration == null || duration! <= 0) return '00:00';
    final minutes = (duration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Subtitle description matching the home screen call log format
  /// (e.g. `Outgoing · 12:34`, `Incoming · 08:21`, or `Missed call`).
  String get timeSubtitle {
    if (isMissed) return 'Missed call';
    final direction = isOutgoing ? 'Outgoing' : 'Incoming';
    if (duration != null && duration! > 0) {
      return '$direction · $formattedDuration';
    }
    return direction;
  }

  /// Formatted date string for UI display (e.g. 'Today', 'Yesterday', 'Mon, 8 Sep').
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diffDays = today.difference(callDate).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (diffDays > 0 && diffDays < 7) {
      return '${weekdays[createdAt.weekday - 1]}, ${createdAt.day} ${months[createdAt.month - 1]}';
    }
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  /// Formatted time string for UI display (e.g. '5:45 PM').
  String get formattedTime {
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    try {
      // Handles Cloud Firestore Timestamp or dynamic objects with toDate()
      final dynamic dynamicValue = value;
      final result = dynamicValue?.toDate();
      if (result is DateTime) return result;
    } catch (_) {}
    return DateTime.now();
  }

  static int? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsedInt = int.tryParse(value);
      if (parsedInt != null) return parsedInt;
      final parts = value.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]);
        final s = int.tryParse(parts[1]);
        if (m != null && s != null) return m * 60 + s;
      } else if (parts.length == 3) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final s = int.tryParse(parts[2]);
        if (h != null && m != null && s != null) return h * 3600 + m * 60 + s;
      }
    }
    return null;
  }
}