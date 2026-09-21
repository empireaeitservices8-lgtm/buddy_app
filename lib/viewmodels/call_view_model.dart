import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/agora_constants.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../core/services/agora_audio_service.dart';
import '../core/services/fcm_service.dart';
import '../data/models/call_model.dart';
import 'base_view_model.dart';

class CallViewModel extends BaseViewModel {
  final IAgoraAudioService _audioService;

  CallModel? _callModel;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isRemoteAudioMuted = false;
  int _durationSeconds = 0;
  Timer? _durationTimer;

  StreamSubscription<bool>? _joinSub;
  StreamSubscription<int>? _userJoinedSub;
  StreamSubscription<int>? _userOfflineSub;
  StreamSubscription<bool>? _remoteMuteSub;
  StreamSubscription<String>? _errorSub;

  CallViewModel({IAgoraAudioService? audioService})
    : _audioService = audioService ?? AgoraAudioService() {
    _subscribeToEngineEvents();
  }

  bool _wasConnected = false;

  // Getters
  CallModel? get callModel => _callModel;
  CallStatus get status => _callModel?.status ?? CallStatus.idle;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isRemoteAudioMuted => _isRemoteAudioMuted;
  int get durationSeconds => _durationSeconds;
  bool get wasConnected => _wasConnected;

  String get formattedDuration {
    final minutes = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _subscribeToEngineEvents() {
    _joinSub = _audioService.onJoinChannelSuccessStream.listen((joined) {
      if (joined) {
        _wasConnected = true;
        _callModel = _callModel?.copyWith(status: CallStatus.connected);
        _startDurationTimer();
        notifyListenersSafely();
      }
    });

    _userJoinedSub = _audioService.onUserJoinedStream.listen((remoteUid) {
      _audioService.stopRingtone();
      _wasConnected = true;
      _callModel = _callModel?.copyWith(status: CallStatus.connected);
      _startDurationTimer();
      notifyListenersSafely();
    });

    _userOfflineSub = _audioService.onUserOfflineStream.listen((remoteUid) {
      _audioService.stopRingtone();
      endCall(reason: 'Call Ended');
    });

    _remoteMuteSub = _audioService.onRemoteAudioMutedStream.listen((muted) {
      _isRemoteAudioMuted = muted;
      notifyListenersSafely();
    });

    _errorSub = _audioService.onErrorStream.listen((errorMsg) {
      _audioService.stopRingtone();
      setError(errorMsg);
      _callModel = _callModel?.copyWith(status: CallStatus.error);
      notifyListenersSafely();
    });
  }

  /// Initiates a 1-to-1 voice call
  Future<void> startCall(CallModel model) async {
    _callModel = model.copyWith(
      status: model.isOutgoing ? CallStatus.calling : CallStatus.ringing,
    );
    _isMuted = false;
    _isSpeakerOn = true;
    _durationSeconds = 0;
    clearError();
    notifyListenersSafely();

    String? token = model.token;
    if (token == null || token.isEmpty) {
      token = AgoraConstants.generateRtcToken(
        channelName: model.channelId,
        uid: model.uid,
      );
      _callModel = _callModel?.copyWith(token: token);
    }

    await _audioService.leaveChannel();

    final success = await _audioService.joinChannel(
      channelId: model.channelId,
      token: token,
      uid: model.uid,
    );

    if (success) {
      if (model.isOutgoing) {
        await _audioService.playRingtone();
      } else {
        _wasConnected = true;
        _callModel = _callModel?.copyWith(status: CallStatus.connected);
        _startDurationTimer();
        notifyListenersSafely();
      }
    } else {
      _callModel = _callModel?.copyWith(status: CallStatus.error);
      setError('Could not connect to voice channel.');
      notifyListenersSafely();
    }
  }

  /// Answers an incoming call
  Future<void> answerCall() async {
    if (_callModel == null) return;
    await _audioService.stopRingtone();
    _callModel = _callModel!.copyWith(status: CallStatus.connected);
    notifyListenersSafely();

    String? token = _callModel!.token;
    if (token == null || token.isEmpty) {
      token = AgoraConstants.generateRtcToken(
        channelName: _callModel!.channelId,
        uid: _callModel!.uid,
      );
      _callModel = _callModel!.copyWith(token: token);
    }

    await _audioService.joinChannel(
      channelId: _callModel!.channelId,
      token: token,
      uid: _callModel!.uid,
    );
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationSeconds = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationSeconds++;
      _callModel = _callModel?.copyWith(durationSeconds: _durationSeconds);
      notifyListenersSafely();
    });
  }

  /// Toggles microphone mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    _audioService.toggleMute(_isMuted);
    notifyListenersSafely();
  }

  /// Toggles speakerphone output
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _audioService.toggleSpeaker(_isSpeakerOn);
    notifyListenersSafely();
  }

  /// Ends the voice call and cleans up resources
  Future<void> endCall({String? reason}) async {
    _durationTimer?.cancel();
    _durationTimer = null;
    await _audioService.leaveChannel();

    final callIdStr = _callModel?.callId;
    if (callIdStr != null && int.tryParse(callIdStr) != null && int.parse(callIdStr) > 0) {
      final callId = int.parse(callIdStr);
      FcmService.cancelCallNotification(callId);
      try {
        await ApiService().post(
          ApiConstants.updateCallStatus(callId),
          data: {
            'status': wasConnected
                ? 'completed'
                : (_callModel?.isOutgoing == true ? 'cancelled' : 'rejected'),
          },
          requiresAuth: true,
        );
      } catch (e) {
        // Fallback or ignore network error on tear-down
      }
    }

    _callModel = _callModel?.copyWith(status: CallStatus.ended);
    notifyListenersSafely();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _joinSub?.cancel();
    _userJoinedSub?.cancel();
    _userOfflineSub?.cancel();
    _remoteMuteSub?.cancel();
    _errorSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
