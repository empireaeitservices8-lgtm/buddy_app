enum CallStatus {
  idle,
  dialing,
  ringing,
  connected,
  ended,
  rejected,
  failed,
}

class CallSessionModel {
  final int callId;
  final String channelId;
  final String? token;
  final String callerName;
  final String callerSubtitle;
  final String? callerAvatar;
  final String rating;
  final bool isPro;
  final bool isIncoming;
  final CallStatus status;
  final int durationSeconds;
  final bool isMuted;
  final bool isSpeakerOn;

  const CallSessionModel({
    required this.callId,
    required this.channelId,
    this.token,
    this.callerName = 'Tester',
    this.callerSubtitle = 'Friendly Chat · Emotional Support',
    this.callerAvatar,
    this.rating = '5.0',
    this.isPro = true,
    this.isIncoming = false,
    this.status = CallStatus.idle,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = false,
  });

  CallSessionModel copyWith({
    int? callId,
    String? channelId,
    String? token,
    String? callerName,
    String? callerSubtitle,
    String? callerAvatar,
    String? rating,
    bool? isPro,
    bool? isIncoming,
    CallStatus? status,
    int? durationSeconds,
    bool? isMuted,
    bool? isSpeakerOn,
  }) {
    return CallSessionModel(
      callId: callId ?? this.callId,
      channelId: channelId ?? this.channelId,
      token: token ?? this.token,
      callerName: callerName ?? this.callerName,
      callerSubtitle: callerSubtitle ?? this.callerSubtitle,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      rating: rating ?? this.rating,
      isPro: isPro ?? this.isPro,
      isIncoming: isIncoming ?? this.isIncoming,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    );
  }

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
