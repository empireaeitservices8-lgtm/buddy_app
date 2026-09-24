import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/agora_service.dart';

class CallFeatureRepository {
  final AgoraService _agoraService;
  final ApiService _apiService;

  CallFeatureRepository({
    AgoraService? agoraService,
    ApiService? apiService,
  })  : _agoraService = agoraService ?? AgoraService(),
        _apiService = apiService ?? ApiService();

  AgoraService get agoraService => _agoraService;

  /// Initialize Agora Engine
  Future<void> initializeEngine() async {
    await _agoraService.initialize();
  }

  /// Join Agora Voice Channel
  Future<bool> joinVoiceChannel({
    required String channelId,
    required String token,
    required int uid,
  }) async {
    return await _agoraService.joinVoiceCall(
      channelId: channelId,
      token: token,
      uid: uid,
    );
  }

  /// Leave Voice Channel
  Future<void> leaveVoiceChannel() async {
    await _agoraService.leaveCall();
  }

  /// Toggle Microphone Mute
  Future<void> setMicrophoneMute(bool muted) async {
    await _agoraService.toggleMute(muted);
  }

  /// Toggle Speakerphone
  Future<void> setSpeakerphoneOn(bool enabled) async {
    await _agoraService.toggleSpeaker(enabled);
  }

  /// Play ringtone while dialing
  Future<void> playRingtone() async {
    await _agoraService.playRingtone();
  }

  /// Stop ringtone
  Future<void> stopRingtone() async {
    await _agoraService.stopRingtone();
  }

  /// Update call status on backend (`POST calls/<callId>/status/`)
  Future<bool> updateCallStatus({
    required int callId,
    required String status,
  }) async {
    if (callId <= 0) return false;
    try {
      String validStatus = status.toLowerCase().trim();
      if (validStatus == 'ended' || validStatus == 'finished') {
        validStatus = 'completed';
      } else if (validStatus == 'declined' || validStatus == 'rejected') {
        validStatus = 'reject';
      }
      final res = await _apiService.post(
        ApiConstants.updateCallStatus(callId),
        data: {'status': validStatus},
        requiresAuth: true,
      );
      return res.isSuccess;
    } catch (e) {
      debugPrint('⚠️ [CallFeatureRepository] updateCallStatus error: $e');
      return false;
    }
  }
}
