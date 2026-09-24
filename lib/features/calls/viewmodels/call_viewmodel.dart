import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/call_session_model.dart';
import '../repositories/call_repository.dart';

class CallViewModel extends ChangeNotifier {
  final CallFeatureRepository _repository;
  CallSessionModel _session;

  Timer? _durationTimer;
  StreamSubscription<int?>? _remoteUserSub;
  bool _isDisposed = false;

  CallViewModel({
    required CallSessionModel session,
    CallFeatureRepository? repository,
  })  : _session = session,
        _repository = repository ?? CallFeatureRepository() {
    _initCallSession();
  }

  CallSessionModel get session => _session;
  bool get isConnected => _session.status == CallStatus.connected;
  bool get isMuted => _session.isMuted;
  bool get isSpeakerOn => _session.isSpeakerOn;
  String get formattedDuration => _session.formattedDuration;
  String get statusText {
    switch (_session.status) {
      case CallStatus.idle:
      case CallStatus.dialing:
        return 'CONNECTING...';
      case CallStatus.ringing:
        return _session.isIncoming ? 'INCOMING CALL' : 'RINGING...';
      case CallStatus.connected:
        return 'ON CALL';
      case CallStatus.ended:
        return 'CALL ENDED';
      case CallStatus.rejected:
        return 'DECLINED';
      case CallStatus.failed:
        return 'FAILED';
    }
  }

  void _initCallSession() {
    // Listen for remote user joined
    _remoteUserSub = _repository.agoraService.onRemoteUserJoined.listen((remoteUid) {
      if (remoteUid != null && _session.status != CallStatus.connected) {
        onCallConnected();
      }
    });

    if (_session.isIncoming) {
      _session = _session.copyWith(status: CallStatus.ringing);
    } else {
      _session = _session.copyWith(status: CallStatus.dialing);
      _repository.playRingtone();
    }
  }

  void onCallConnected() {
    _repository.stopRingtone();
    _session = _session.copyWith(status: CallStatus.connected);
    _startDurationTimer();
    _notifySafely();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _session = _session.copyWith(durationSeconds: _session.durationSeconds + 1);
      _notifySafely();
    });
  }

  Future<void> toggleMute() async {
    final newMute = !_session.isMuted;
    _session = _session.copyWith(isMuted: newMute);
    await _repository.setMicrophoneMute(newMute);
    _notifySafely();
  }

  Future<void> toggleSpeaker() async {
    final newSpeaker = !_session.isSpeakerOn;
    _session = _session.copyWith(isSpeakerOn: newSpeaker);
    await _repository.setSpeakerphoneOn(newSpeaker);
    _notifySafely();
  }

  Future<void> acceptCall({int localUid = 0}) async {
    _session = _session.copyWith(status: CallStatus.dialing);
    _notifySafely();

    final success = await _repository.joinVoiceChannel(
      channelId: _session.channelId,
      token: _session.token ?? '',
      uid: localUid,
    );

    if (success) {
      onCallConnected();
    } else {
      _session = _session.copyWith(status: CallStatus.failed);
      _notifySafely();
    }
  }

  Future<void> rejectCall() async {
    _durationTimer?.cancel();
    await _repository.stopRingtone();
    await _repository.leaveVoiceChannel();
    await _repository.updateCallStatus(
      callId: _session.callId,
      status: 'reject',
    );
    _session = _session.copyWith(status: CallStatus.rejected);
    _notifySafely();
  }

  Future<void> endCall() async {
    _durationTimer?.cancel();
    await _repository.stopRingtone();
    final wasConnected = _session.status == CallStatus.connected;
    await _repository.leaveVoiceChannel();

    final statusToSend = wasConnected
        ? 'completed'
        : (_session.isIncoming ? 'reject' : 'cancelled');

    await _repository.updateCallStatus(
      callId: _session.callId,
      status: statusToSend,
    );

    _session = _session.copyWith(status: CallStatus.ended);
    _notifySafely();
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _durationTimer?.cancel();
    _remoteUserSub?.cancel();
    super.dispose();
  }
}
