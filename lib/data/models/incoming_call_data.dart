import 'dart:convert';

/// Lightweight model representing an incoming call notification
/// received via FCM push on the agent side.
class IncomingCallData {
  final int callId;
  final String callerName;
  final String? callerAvatar;
  final String? callerGender;
  final String channelName;
  final String? category;
  final String? token; // Agora token if backend provides one
  final int uid;

  const IncomingCallData({
    required this.callId,
    required this.callerName,
    this.callerAvatar,
    this.callerGender,
    required this.channelName,
    this.category,
    this.token,
    this.uid = 0,
  });

  bool get isFemale {
    final g = (callerGender ?? '').trim().toLowerCase();
    if (g == 'female' ||
        g == 'woman' ||
        g == 'girl' ||
        g == 'lady' ||
        g == 'f' ||
        g == 'w') {
      return true;
    }
    if (g == 'male' ||
        g == 'man' ||
        g == 'boy' ||
        g == 'guy' ||
        g == 'm') {
      return false;
    }
    final n = callerName.trim().toLowerCase();
    return n.endsWith('a') ||
        n.endsWith('i') ||
        n.endsWith('e') ||
        n.contains('girl');
  }

  bool get isMale => !isFemale;

  String get avatarAsset =>
      isFemale ? 'assets/images/Girl2.png' : 'assets/images/Boy2.png';

  /// Returns true if this is a legitimate call with an ID or Agora channel name
  bool get isValid => callId > 0 || channelName.trim().isNotEmpty;

  /// Parses the FCM `data` map into an [IncomingCallData] instance.
  ///
  /// Expected keys: `call_id`, `caller_name`, `channel_name`,
  /// and optionally `caller_avatar`, `category`, `agora_token`, `uid`.
  factory IncomingCallData.fromFcmData(Map<String, dynamic> rawData) {
    Map<String, dynamic> data = Map<String, dynamic>.from(rawData);

    // Unpack stringified JSON payloads if present (e.g. data['data'] = '{"call_id": 73}')
    for (final key in ['data', 'call', 'payload', 'message', 'custom', 'notification']) {
      if (data[key] is String && (data[key] as String).trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(data[key] as String);
          if (decoded is Map) {
            data.addAll(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      } else if (data[key] is Map) {
        data.addAll(Map<String, dynamic>.from(data[key] as Map));
      }
    }

    final parsedCallId = _parseInt(
      data['call_id'] ??
          data['callId'] ??
          data['callID'] ??
          data['id'] ??
          data['pk'] ??
          data['session_id'],
    );

    String rawChannel = data['channel_name']?.toString() ??
        data['channelName']?.toString() ??
        data['channel']?.toString() ??
        data['channel_id']?.toString() ??
        data['channelId']?.toString() ??
        data['agora_channel']?.toString() ??
        data['room_name']?.toString() ??
        data['room']?.toString() ??
        '';

    if (rawChannel.trim().isEmpty && parsedCallId > 0) {
      rawChannel = 'gabby_call_$parsedCallId';
    }

    String parsedCallerName = data['caller_name']?.toString() ??
        data['callerName']?.toString() ??
        data['caller_display_name']?.toString() ??
        data['client_name']?.toString() ??
        data['clientName']?.toString() ??
        data['caller_username']?.toString() ??
        data['caller']?.toString() ??
        data['user_name']?.toString() ??
        data['username']?.toString() ??
        data['name']?.toString() ??
        '';

    if (parsedCallerName.trim().isEmpty) {
      final rawTitle = data['title']?.toString() ?? '';
      final lowerTitle = rawTitle.toLowerCase();
      if (rawTitle.isNotEmpty &&
          !lowerTitle.contains('call') &&
          !lowerTitle.contains('notification') &&
          !lowerTitle.contains('incoming') &&
          !lowerTitle.contains('reject') &&
          !lowerTitle.contains('cancel') &&
          !lowerTitle.contains('end') &&
          !lowerTitle.contains('audio')) {
        parsedCallerName = rawTitle;
      } else {
        parsedCallerName = 'Caller';
      }
    }

    return IncomingCallData(
      callId: parsedCallId,
      callerName: parsedCallerName,
      callerAvatar: data['caller_avatar']?.toString() ??
          data['callerAvatar']?.toString() ??
          data['avatar']?.toString() ??
          data['profile_picture']?.toString() ??
          data['profile_picture_url']?.toString(),
      callerGender: data['caller_gender']?.toString() ??
          data['gender']?.toString() ??
          data['user_gender']?.toString() ??
          data['client_gender']?.toString() ??
          (data['caller'] is Map ? data['caller']['gender']?.toString() : null) ??
          (data['user'] is Map ? data['user']['gender']?.toString() : null),
      channelName: rawChannel,
      category: data['category']?.toString() ??
          data['category_name']?.toString() ??
          data['topic']?.toString() ??
          data['profession']?.toString(),
      token: data['agora_token']?.toString() ??
          data['token']?.toString() ??
          data['agoraToken']?.toString() ??
          data['rtc_token']?.toString() ??
          data['rtcToken']?.toString() ??
          data['agora_rtc_token']?.toString(),
      uid: _parseInt(
        data['uid'] ??
            data['agent_uid'] ??
            data['agent_id'] ??
            data['receiver_id'] ??
            data['receiverId'],
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() =>
      'IncomingCallData(callId: $callId, callerName: $callerName, '
      'channelName: $channelName, category: $category)';
}
