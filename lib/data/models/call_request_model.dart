import 'call_model.dart';

/// Sub-model for category info in call response
class CallCategoryInfo {
  final int id;
  final String name;

  const CallCategoryInfo({
    required this.id,
    required this.name,
  });

  factory CallCategoryInfo.fromJson(Map<String, dynamic> json) {
    return CallCategoryInfo(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

/// Sub-model for matched agent in call response
class CallAgentInfo {
  final int id;
  final String name;
  final String? profilePicture;

  const CallAgentInfo({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory CallAgentInfo.fromJson(Map<String, dynamic> json) {
    return CallAgentInfo(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'profile_picture': profilePicture,
  };
}

/// Domain model for response returned by `calls/request/`
class CallRequestResponse {
  final bool success;
  final String message;
  final int callId;
  final String status;
  final CallCategoryInfo? category;
  final CallAgentInfo? agent;
  final String channelName;
  final String? agoraToken;
  final int? uid;
  final String? requestedAt;

  const CallRequestResponse({
    this.success = true,
    this.message = '',
    this.callId = 0,
    this.status = 'RINGING',
    this.category,
    this.agent,
    this.channelName = '',
    this.agoraToken,
    this.uid,
    this.requestedAt,
  });

  factory CallRequestResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return CallRequestResponse(
      success: rawData['success'] == true || json['success'] == true,
      message: rawData['message']?.toString() ?? json['message']?.toString() ?? '',
      callId: rawData['call_id'] is int
          ? rawData['call_id'] as int
          : int.tryParse(rawData['call_id']?.toString() ?? '0') ?? 0,
      status: rawData['status']?.toString() ?? 'RINGING',
      category: rawData['category'] is Map<String, dynamic>
          ? CallCategoryInfo.fromJson(rawData['category'] as Map<String, dynamic>)
          : null,
      agent: rawData['agent'] is Map<String, dynamic>
          ? CallAgentInfo.fromJson(rawData['agent'] as Map<String, dynamic>)
          : null,
      channelName: rawData['channel_name']?.toString() ?? '',
      agoraToken: rawData['agora_token']?.toString() ?? rawData['token']?.toString(),
      uid: rawData['uid'] is int
          ? rawData['uid'] as int
          : int.tryParse(rawData['uid']?.toString() ?? ''),
      requestedAt: rawData['requested_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'call_id': callId,
    'status': status,
    'category': category?.toJson(),
    'agent': agent?.toJson(),
    'channel_name': channelName,
    'agora_token': agoraToken,
    'uid': uid,
    'requested_at': requestedAt,
  };

  /// Converts this response into a [CallModel] for Agora voice call handling
  CallModel toCallModel({
    required String currentUserId,
    required String currentUserName,
    String? token,
  }) {
    return CallModel(
      callId: callId.toString(),
      callerId: currentUserId,
      callerName: currentUserName,
      receiverId: agent?.id.toString() ?? '',
      receiverName: agent?.name.isNotEmpty == true ? agent!.name : (category?.name ?? 'Agent'),
      receiverAvatar: agent?.profilePicture,
      channelId: channelName,
      token: token ?? agoraToken,
      status: CallStatus.ringing,
      isOutgoing: true,
    );
  }
}
