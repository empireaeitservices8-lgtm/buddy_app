import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/agora_constants.dart';
import '../utils/call_sound_helper.dart';

enum AgoraCallState {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

enum AgoraCallType {
  voice,
  video,
}

/// Centralized Singleton managing Agora RTC Engine lifecycle, audio routing,
/// microphone/camera stream toggling, channel joining, and remote participant events.
class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isPlayingRingtone = false;
  static const int _ringtoneSoundId = 101;
  static const int _beepSoundId = 102;

  AgoraCallState _callState = AgoraCallState.idle;
  AgoraCallType _callType = AgoraCallType.voice;
  String? _activeChannelId;
  int? _localUid;
  int? _remoteUid;
  bool _isLocalMuted = false;
  bool _isSpeakerPhoneOn = true;
  bool _isVideoEnabled = false;

  final StreamController<AgoraCallState> _callStateController =
      StreamController<AgoraCallState>.broadcast();
  final StreamController<int?> _remoteUserJoinedController =
      StreamController<int?>.broadcast();
  final StreamController<bool> _remoteAudioStateController =
      StreamController<bool>.broadcast();

  // Getters
  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  bool get isPlayingRingtone => _isPlayingRingtone;
  AgoraCallState get callState => _callState;
  AgoraCallType get callType => _callType;
  String? get activeChannelId => _activeChannelId;
  int? get localUid => _localUid;
  int? get remoteUid => _remoteUid;
  bool get isLocalMuted => _isLocalMuted;
  bool get isSpeakerPhoneOn => _isSpeakerPhoneOn;
  bool get isVideoEnabled => _isVideoEnabled;

  Stream<AgoraCallState> get callStateStream => _callStateController.stream;
  Stream<int?> get remoteUserJoinedStream => _remoteUserJoinedController.stream;
  Stream<bool> get remoteAudioStateStream => _remoteAudioStateController.stream;

  /// Initializes the Agora RTC Engine instance with the configured App ID.
  Future<bool> initialize() async {
    if (_isInitialized && _engine != null) return true;

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: AgoraConstants.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _registerEventHandlers();
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
        await _engine!.setDefaultAudioRouteToSpeakerphone(true);
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
      debugPrint('[AgoraService] Initialization Error: $e');
      _setCallState(AgoraCallState.error);
      return false;
    }
  }

  /// Requests runtime microphone and camera permissions
  Future<bool> requestPermissions({bool requireCamera = false}) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('[AgoraService] Microphone permission denied');
      return false;
    }

    if (requireCamera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        debugPrint('[AgoraService] Camera permission denied');
        return false;
      }
    }
    return true;
  }

  /// Joins a voice call channel
  Future<bool> joinVoiceCall({
    required String channelId,
    String? token,
    int uid = 0,
  }) async {
    final permissionsGranted = await requestPermissions(requireCamera: false);
    if (!permissionsGranted) return false;

    await initialize();
    if (_engine == null) return false;

    _callType = AgoraCallType.voice;
    _activeChannelId = channelId;
    _setCallState(AgoraCallState.connecting);

    try {
      try {
        await _engine!.disableVideo();
      } catch (_) {}
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
        await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      } catch (_) {}
      _isSpeakerPhoneOn = true;
      _isLocalMuted = false;

      const options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
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
      debugPrint('[AgoraService] joinVoiceCall Error: $e');
      _setCallState(AgoraCallState.error);
      return false;
    }
  }

  /// Joins a video call channel
  Future<bool> joinVideoCall({
    required String channelId,
    String? token,
    int uid = 0,
  }) async {
    final permissionsGranted = await requestPermissions(requireCamera: true);
    if (!permissionsGranted) return false;

    await initialize();
    if (_engine == null) return false;

    _callType = AgoraCallType.video;
    _activeChannelId = channelId;
    _setCallState(AgoraCallState.connecting);

    try {
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.startPreview();
      await _engine!.setEnableSpeakerphone(true);
      _isSpeakerPhoneOn = true;
      _isLocalMuted = false;
      _isVideoEnabled = true;

      final options = const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      );

      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelId,
        uid: uid,
        options: options,
      );

      return true;
    } catch (e) {
      debugPrint('[AgoraService] joinVideoCall Error: $e');
      _setCallState(AgoraCallState.error);
      return false;
    }
  }

  /// Plays continuous ringback tone while waiting for the remote participant to answer
  Future<void> playRingtone() async {
    if (_isPlayingRingtone) return;
    try {
      final ringtonePath = await CallSoundHelper.getRingtonePath();
      if (ringtonePath == null || ringtonePath.isEmpty) return;

      _isPlayingRingtone = true;
      if (_engine != null) {
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
        debugPrint('📞 [AgoraService] Ringtone started playing (soundId: $_ringtoneSoundId)');
      }
    } catch (e) {
      debugPrint('⚠️ [AgoraService] playRingtone error: $e');
      // Fallback to startAudioMixing if effect manager fails
      try {
        final ringtonePath = await CallSoundHelper.getRingtonePath();
        if (ringtonePath != null && _engine != null) {
          await _engine!.startAudioMixing(
            filePath: ringtonePath,
            loopback: true,
            cycle: -1,
          );
        }
      } catch (e2) {
        debugPrint('⚠️ [AgoraService] Audio mixing fallback error: $e2');
      }
    }
  }

  /// Stops the ringback tone immediately (e.g. when answered or call ends)
  Future<void> stopRingtone() async {
    if (!_isPlayingRingtone) return;
    _isPlayingRingtone = false;
    try {
      if (_engine != null) {
        await _engine!.stopEffect(_ringtoneSoundId);
        await _engine!.stopAllEffects();
        try {
          await _engine?.stopAudioMixing();
        } catch (_) {}
        debugPrint('📞 [AgoraService] Ringtone stopped');
      }
    } catch (e) {
      debugPrint('⚠️ [AgoraService] stopRingtone error: $e');
    }
  }

  /// Plays a short alert beep tone
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
      debugPrint('⚠️ [AgoraService] playAlertBeep error: $e');
    }
  }

  /// Leaves the current Agora channel and resets connection state
  Future<void> leaveCall() async {
    await stopRingtone();
    try {
      if (_engine != null) {
        if (_isVideoEnabled) {
          await _engine!.stopPreview();
          await _engine!.disableVideo();
        }
        await _engine!.leaveChannel();
      }
    } catch (e) {
      debugPrint('[AgoraService] leaveCall Error: $e');
    } finally {
      _activeChannelId = null;
      _remoteUid = null;
      _isLocalMuted = false;
      _isVideoEnabled = false;
      _setCallState(AgoraCallState.idle);
      _remoteUserJoinedController.add(null);
    }
  }

  /// Toggles the local microphone mute state
  Future<void> toggleMute(bool isMuted) async {
    if (_engine == null) return;
    try {
      await _engine!.muteLocalAudioStream(isMuted);
      _isLocalMuted = isMuted;
    } catch (e) {
      debugPrint('[AgoraService] toggleMute Error: $e');
    }
  }

  /// Toggles audio output between loudspeaker and earpiece
  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    if (_engine == null) return;
    try {
      await _engine!.setEnableSpeakerphone(isSpeakerOn);
      _isSpeakerPhoneOn = isSpeakerOn;
    } catch (e) {
      debugPrint('[AgoraService] toggleSpeaker Error: $e');
    }
  }

  /// Toggles the local video stream on/off during a video call
  Future<void> toggleVideo(bool enabled) async {
    if (_engine == null) return;
    try {
      await _engine!.muteLocalVideoStream(!enabled);
      _isVideoEnabled = enabled;
    } catch (e) {
      debugPrint('[AgoraService] toggleVideo Error: $e');
    }
  }

  /// Switches between front and back cameras
  Future<void> switchCamera() async {
    if (_engine == null) return;
    try {
      await _engine!.switchCamera();
    } catch (e) {
      debugPrint('[AgoraService] switchCamera Error: $e');
    }
  }

  /// Registers Agora Event Handlers
  void _registerEventHandlers() {
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('[AgoraService] onJoinChannelSuccess: ${connection.channelId}, uid: ${connection.localUid}');
          _localUid = connection.localUid;
          try {
            _engine?.setEnableSpeakerphone(true);
          } catch (_) {}
          _setCallState(AgoraCallState.connected);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('[AgoraService] onUserJoined: remoteUid $remoteUid');
          stopRingtone();
          _remoteUid = remoteUid;
          _remoteUserJoinedController.add(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('[AgoraService] onUserOffline: remoteUid $remoteUid, reason: $reason');
          stopRingtone();
          _remoteUid = null;
          if (!_remoteUserJoinedController.isClosed) {
            _remoteUserJoinedController.add(null);
          }
        },
        onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
          debugPrint('[AgoraService] onUserMuteAudio: remoteUid $remoteUid, muted: $muted');
          _remoteAudioStateController.add(!muted);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[AgoraService] Agora Error: $err, msg: $msg');
          stopRingtone();
          _setCallState(AgoraCallState.error);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('[AgoraService] onLeaveChannel');
          stopRingtone();
          _setCallState(AgoraCallState.idle);
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[AgoraService] Token will expire soon: $token');
        },
      ),
    );
  }

  void _setCallState(AgoraCallState state) {
    _callState = state;
    _callStateController.add(state);
  }

  /// Disposes Agora RTC Engine resources
  Future<void> dispose() async {
    await stopRingtone();
    await leaveCall();
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
  }
}
