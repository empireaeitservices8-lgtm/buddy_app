import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/agora_constants.dart';

import '../utils/call_sound_helper.dart';

abstract class IAgoraAudioService {
  Future<bool> initialize();
  Future<bool> joinChannel({required String channelId, String? token, int uid});
  Future<void> leaveChannel();
  Future<void> playRingtone();
  Future<void> stopRingtone();
  Future<void> playAlertBeep();
  Future<void> toggleMute(bool isMuted);
  Future<void> toggleSpeaker(bool isSpeakerOn);
  Future<void> dispose();

  Stream<bool> get onJoinChannelSuccessStream;
  Stream<int> get onUserJoinedStream;
  Stream<int> get onUserOfflineStream;
  Stream<bool> get onRemoteAudioMutedStream;
  Stream<String> get onErrorStream;
}

class AgoraAudioService implements IAgoraAudioService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isPlayingRingtone = false;
  bool _shouldPlayRingtone = false;
  static const int _ringtoneSoundId = 201;
  static const int _beepSoundId = 202;

  final StreamController<bool> _joinSuccessController = StreamController<bool>.broadcast();
  final StreamController<int> _userJoinedController = StreamController<int>.broadcast();
  final StreamController<int> _userOfflineController = StreamController<int>.broadcast();
  final StreamController<bool> _remoteAudioMutedController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  @override
  Stream<bool> get onJoinChannelSuccessStream => _joinSuccessController.stream;

  @override
  Stream<int> get onUserJoinedStream => _userJoinedController.stream;

  @override
  Stream<int> get onUserOfflineStream => _userOfflineController.stream;

  @override
  Stream<bool> get onRemoteAudioMutedStream => _remoteAudioMutedController.stream;

  @override
  Stream<String> get onErrorStream => _errorController.stream;

  @override
  Future<bool> initialize() async {
    if (_isInitialized && _engine != null) return true;

    // 1. Check & request microphone permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('[AgoraAudioService] Microphone permission denied');
      _errorController.add('Microphone permission required for voice calls');
      return false;
    }

    try {
      // 2. Instantiate Agora RTC Engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: AgoraConstants.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // 3. Register Event Handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('[AgoraAudioService] onJoinChannelSuccess: ${connection.channelId}, uid: ${connection.localUid}');
            try {
              _engine?.setEnableSpeakerphone(false);
            } catch (_) {}
            if (!_joinSuccessController.isClosed) {
              _joinSuccessController.add(true);
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('[AgoraAudioService] onUserJoined: remoteUid $remoteUid');
            stopRingtone();
            if (!_userJoinedController.isClosed) {
              _userJoinedController.add(remoteUid);
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('[AgoraAudioService] onUserOffline: remoteUid $remoteUid, reason: $reason');
            stopRingtone();
            if (!_userOfflineController.isClosed) {
              _userOfflineController.add(remoteUid);
            }
          },
          onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
            debugPrint('[AgoraAudioService] onUserMuteAudio: remoteUid $remoteUid, muted: $muted');
            if (!_remoteAudioMutedController.isClosed) {
              _remoteAudioMutedController.add(muted);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('[AgoraAudioService] Agora Error: $err, msg: $msg');
            stopRingtone();
            if (!_errorController.isClosed) {
              _errorController.add(msg);
            }
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('[AgoraAudioService] onLeaveChannel');
            stopRingtone();
          },
        ),
      );

      // 4. Configure Audio Subsystems
      await _engine!.enableAudio();
      try {
        await _engine!.enableLocalAudio(true);
      } catch (_) {}
      try {
        await _engine!.muteLocalAudioStream(false);
      } catch (_) {}
      try {
        await _engine!.muteAllRemoteAudioStreams(false);
      } catch (_) {}
      try {
        await _engine!.setDefaultAudioRouteToSpeakerphone(false);
      } catch (_) {}
      try {
        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileSpeechStandard,
          scenario: AudioScenarioType.audioScenarioDefault,
        );
      } catch (_) {}

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[AgoraAudioService] Initialization Exception: $e');
      _errorController.add('Failed to initialize Agora RTC engine: $e');
      return false;
    }
  }

  @override
  Future<void> playRingtone() async {
    _shouldPlayRingtone = true;
    if (_isPlayingRingtone) return;
    try {
      final ringtonePath = await CallSoundHelper.getRingtonePath();
      if (!_shouldPlayRingtone) {
        debugPrint('📞 [AgoraAudioService] Ringtone cancelled before playback began');
        return;
      }
      if (ringtonePath == null || ringtonePath.isEmpty) return;

      _isPlayingRingtone = true;
      if (_engine != null && _shouldPlayRingtone) {
        await _engine!.stopAllEffects();
        await _engine!.playEffect(
          soundId: _ringtoneSoundId,
          filePath: ringtonePath,
          loopCount: -1,
          pitch: 1.0,
          pan: 0.0,
          gain: 100,
          publish: false,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [AgoraAudioService] playRingtone error: $e');
      if (!_shouldPlayRingtone) return;
      try {
        final ringtonePath = await CallSoundHelper.getRingtonePath();
        if (ringtonePath != null && _engine != null && _shouldPlayRingtone) {
          await _engine!.startAudioMixing(
            filePath: ringtonePath,
            loopback: true,
            cycle: -1,
          );
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> stopRingtone() async {
    _shouldPlayRingtone = false;
    _isPlayingRingtone = false;
    try {
      if (_engine != null) {
        try {
          await _engine!.stopEffect(_ringtoneSoundId);
        } catch (_) {}
        try {
          await _engine!.stopAllEffects();
        } catch (_) {}
        try {
          await _engine?.stopAudioMixing();
        } catch (_) {}
        debugPrint('📞 [AgoraAudioService] Ringtone stopped completely');
      }
    } catch (e) {
      debugPrint('⚠️ [AgoraAudioService] stopRingtone error: $e');
    }
  }

  @override
  Future<void> playAlertBeep() async {
    try {
      final beepPath = await CallSoundHelper.getBeepSoundPath();
      if (beepPath == null || beepPath.isEmpty) return;

      if (_engine != null) {
        await _engine!.playEffect(
          soundId: _beepSoundId,
          filePath: beepPath,
          loopCount: 1,
          pitch: 1.0,
          pan: 0.0,
          gain: 100,
          publish: false,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [AgoraAudioService] playAlertBeep error: $e');
    }
  }

  @override
  Future<bool> joinChannel({
    required String channelId,
    String? token,
    int uid = 0,
  }) async {
    final ready = await initialize();
    if (!ready || _engine == null) return false;

    try {
      await _engine!.enableAudio();
      try {
        await _engine!.enableLocalAudio(true);
      } catch (_) {}
      try {
        await _engine!.muteLocalAudioStream(false);
      } catch (_) {}
      try {
        await _engine!.muteAllRemoteAudioStreams(false);
      } catch (_) {}
      try {
        await _engine!.setDefaultAudioRouteToSpeakerphone(false);
      } catch (_) {}

      const options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        enableAudioRecordingOrPlayout: true,
      );

      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelId,
        uid: uid,
        options: options,
      );
      return true;
    } catch (e) {
      debugPrint('[AgoraAudioService] joinChannel Exception: $e');
      _errorController.add('Failed to join audio channel: $e');
      return false;
    }
  }

  @override
  Future<void> leaveChannel() async {
    await stopRingtone();
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
      }
    } catch (e) {
      debugPrint('[AgoraAudioService] leaveChannel Exception: $e');
    }
  }

  @override
  Future<void> toggleMute(bool isMuted) async {
    if (_engine == null) return;
    try {
      await _engine!.muteLocalAudioStream(isMuted);
    } catch (e) {
      debugPrint('[AgoraAudioService] toggleMute Exception: $e');
    }
  }

  @override
  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    if (_engine == null) return;
    try {
      await _engine!.setEnableSpeakerphone(isSpeakerOn);
    } catch (e) {
      debugPrint('[AgoraAudioService] toggleSpeaker Exception: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await stopRingtone();
    await leaveChannel();
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
  }
}
