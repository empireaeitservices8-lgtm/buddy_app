enum CallStatus {
  idle,
  calling,
  ringing,
  connected,
  reconnecting,
  ended,
  error,
}

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final String channelId;
  final String? token;
  final int uid;
  final CallStatus status;
  final int durationSeconds;
  final bool isOutgoing;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.channelId,
    this.token,
    this.uid = 0,
    this.status = CallStatus.idle,
    this.durationSeconds = 0,
    this.isOutgoing = true,
  });

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    String? channelId,
    String? token,
    int? uid,
    CallStatus? status,
    int? durationSeconds,
    bool? isOutgoing,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      channelId: channelId ?? this.channelId,
      token: token ?? this.token,
      uid: uid ?? this.uid,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isOutgoing: isOutgoing ?? this.isOutgoing,
    );
  }

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
