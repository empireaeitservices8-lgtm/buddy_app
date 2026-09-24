import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/agora_constants.dart';
import '../constants/api_constants.dart';
import '../navigation/navigation_service.dart';
import '../network/api_service.dart';
import '../network/token_manager.dart';
import '../../data/models/call_model.dart';
import '../../data/models/incoming_call_data.dart';
import '../../views/call/audio_call_screen.dart';
import 'agora_service.dart';
import 'fcm_service.dart';

/// Centralized Manager that handles incoming audio calls across the entire application
/// regardless of which screen the agent is currently viewing.
class IncomingCallManager extends ChangeNotifier {
  static final IncomingCallManager _instance = IncomingCallManager._internal();
  static IncomingCallManager get instance => _instance;
  factory IncomingCallManager() => _instance;

  IncomingCallManager._internal();

  final AgoraService _agoraService = AgoraService();
  final ApiService _apiService = ApiService();

  bool _isInitialized = false;
  bool _hasIncomingCall = false;
  bool _isAccepting = false;
  IncomingCallData? _incomingCallData;

  Timer? _incomingCallPollTimer;
  StreamSubscription? _fcmCallSubscription;
  StreamSubscription? _fcmTapSubscription;
  StreamSubscription? _fcmNativeSubscription;
  StreamSubscription? _fcmTokenSubscription;

  int? _lastHandledCallId;
  int _lastHandledCallTime = 0;

  // Getters
  bool get hasIncomingCall => _hasIncomingCall;
  bool get isAccepting => _isAccepting;
  IncomingCallData? get incomingCallData => _incomingCallData;
  String get callerName => _incomingCallData?.callerName ?? 'Caller';
  String get callTopic => _incomingCallData?.category != null &&
          _incomingCallData!.category!.isNotEmpty
      ? 'Topic: ${_incomingCallData!.category}'
      : 'Incoming Call';
  String get callRateText => '5 Coins/sec';

  /// Initializes listeners for FCM messages, notification taps, and native intents.
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _listenForIncomingCalls();
    // Check if app was opened with a pending incoming call
    checkPendingCall();
  }

  Future<bool> _isAgentUser() async {
    final role = await TokenManager().getUserRole();
    return role?.toLowerCase() == 'agent';
  }

  bool _shouldHandleIncomingCall(int callId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastHandledCallId == callId && (now - _lastHandledCallTime) < 4000) {
      return false;
    }
    _lastHandledCallId = callId;
    _lastHandledCallTime = now;
    return true;
  }

  void _listenForIncomingCalls() {
    _fcmCallSubscription?.cancel();
    _fcmTapSubscription?.cancel();
    _fcmNativeSubscription?.cancel();
    _fcmTokenSubscription?.cancel();

    // 1. Foreground FCM message
    _fcmCallSubscription = FcmService.onMessageStream.listen((message) async {
      final payload = _extractFullPayload(message);
      if (isCallCancellationPayload(
        payload,
        title: message.notification?.title,
        body: message.notification?.body,
      )) {
        final cancelCallId = int.tryParse(
          payload['call_id']?.toString() ?? payload['id']?.toString() ?? '',
        );
        if (_hasIncomingCall &&
            (cancelCallId == null ||
                cancelCallId == _incomingCallData?.callId)) {
          dismissIncomingCall(reason: 'Caller cancelled call via FCM foreground');
        }
      } else if (_isCallPayload(payload)) {
        if (!await _isAgentUser()) return;
        final parsed = IncomingCallData.fromFcmData(payload);
        if (parsed.isValid && _shouldHandleIncomingCall(parsed.callId)) {
          triggerIncomingCall(parsed);
        }
      }
    });

    // 2. Background / Terminated notification tap
    _fcmTapSubscription =
        FcmService.onNotificationTapStream.listen((message) async {
      final payload = _extractFullPayload(message);
      if (isCallCancellationPayload(
        payload,
        title: message.notification?.title,
        body: message.notification?.body,
      )) {
        final cancelCallId = int.tryParse(
          payload['call_id']?.toString() ?? payload['id']?.toString() ?? '',
        );
        if (_hasIncomingCall &&
            (cancelCallId == null ||
                cancelCallId == _incomingCallData?.callId)) {
          dismissIncomingCall(reason: 'Caller cancelled call');
        }
      } else if (_isCallPayload(payload)) {
        if (!await _isAgentUser()) return;
        final parsed = IncomingCallData.fromFcmData(payload);
        if (parsed.isValid && _shouldHandleIncomingCall(parsed.callId)) {
          triggerIncomingCall(parsed);
        }
      }
    });

    // 3. Native Android Intent
    _fcmNativeSubscription =
        FcmService.onNativeCallStream.listen((data) async {
      if (isCallCancellationPayload(data)) {
        final cancelCallId = int.tryParse(
          data['call_id']?.toString() ?? data['id']?.toString() ?? '',
        );
        if (_hasIncomingCall &&
            (cancelCallId == null ||
                cancelCallId == _incomingCallData?.callId)) {
          dismissIncomingCall(reason: 'Caller cancelled call via Intent');
        }
      } else if (_isCallPayload(data)) {
        if (!await _isAgentUser()) return;
        final parsed = IncomingCallData.fromFcmData(data);
        if (parsed.isValid && _shouldHandleIncomingCall(parsed.callId)) {
          triggerIncomingCall(parsed);
        }
      }
    });

    // 4. Token refresh sync
    _fcmTokenSubscription =
        FcmService.onTokenRefreshStream.listen((newToken) {
      FcmService.sendFcmTokenToBackend(newToken);
    });
  }

  void triggerIncomingCall(IncomingCallData parsed) {
    if (_agoraService.callState == AgoraCallState.connected) {
      debugPrint(
        '⚠️ [IncomingCallManager] Ignoring incoming call #${parsed.callId} because agent is already on an active call.',
      );
      return;
    }

    _incomingCallData = parsed;
    _hasIncomingCall = true;
    _isAccepting = false;

    debugPrint(
      '📞 [IncomingCallManager] Triggering incoming call: ${parsed.callerName} (ID: ${parsed.callId}, Channel: ${parsed.channelName})',
    );

    // Vibrate and start ringtone
    HapticFeedback.vibrate();
    _agoraService.playRingtone();

    _startIncomingCallVerification(parsed);
    notifyListeners();
  }

  void _startIncomingCallVerification(IncomingCallData callData) {
    _incomingCallPollTimer?.cancel();
    int elapsedMs = 0;
    _incomingCallPollTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      elapsedMs += 1500;
      if (!_hasIncomingCall ||
          _incomingCallData == null ||
          _incomingCallData?.callId != callData.callId) {
        timer.cancel();
        _incomingCallPollTimer = null;
        return;
      }
      if (elapsedMs >= 45000) {
        timer.cancel();
        _incomingCallPollTimer = null;
        dismissIncomingCall(reason: 'Incoming call timed out after 45s');
        return;
      }

      // Check backend to verify if caller cancelled or call was ended
      try {
        final token = await TokenManager().getAccessToken() ??
            await TokenManager().getVerificationToken();
        final options = token != null && token.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null;

        final response = await _apiService.get(
          ApiConstants.agentDashboard,
          options: options,
          requiresAuth: true,
        );

        if (response.isSuccess && response.rawData is Map) {
          final raw = response.rawData as Map<String, dynamic>;
          final dataJson = raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw;

          Map<String, dynamic>? activeCallMap;
          for (final key in [
            'incoming_call',
            'active_call',
            'pending_call',
            'call',
            'current_call',
            'call_request',
            'latest_call',
          ]) {
            if (dataJson[key] is Map<String, dynamic>) {
              activeCallMap = dataJson[key] as Map<String, dynamic>;
              break;
            } else if (dataJson[key] is Map) {
              activeCallMap = Map<String, dynamic>.from(dataJson[key] as Map);
              break;
            }
          }

          if (activeCallMap != null) {
            final activeCallId =
                activeCallMap['id'] ?? activeCallMap['call_id'];
            final status =
                activeCallMap['status']?.toString().toLowerCase() ?? '';
            final isCancelled = status == 'cancelled' ||
                status == 'cancel' ||
                status == 'rejected' ||
                status == 'reject' ||
                status == 'completed' ||
                status == 'ended' ||
                status == 'missed';

            if (isCancelled ||
                (activeCallId != null &&
                    activeCallId.toString() != callData.callId.toString())) {
              debugPrint(
                '📞 [IncomingCallManager] Call #${callData.callId} is no longer active on server ($status). Dismissing.',
              );
              timer.cancel();
              _incomingCallPollTimer = null;
              dismissIncomingCall(reason: 'Caller cancelled or call ended');
              return;
            }
          }
        }
      } catch (_) {}
    });
  }

  /// Checks for any pending call from FCM background/notification taps or native Intent
  Future<void> checkPendingCall() async {
    if (!await _isAgentUser()) return;

    // 1. In-memory pending initial message
    final pendingMsg = FcmService.popPendingInitialMessage();
    if (pendingMsg != null) {
      final payload = _extractFullPayload(pendingMsg);
      if (isCallCancellationPayload(payload)) {
        dismissIncomingCall(reason: 'Initial message was call cancellation');
        return;
      } else if (_isCallPayload(payload) && !_hasIncomingCall) {
        final parsed = IncomingCallData.fromFcmData(payload);
        if (parsed.isValid) {
          triggerIncomingCall(parsed);
          return;
        }
      }
    }

    // 2. SharedPreferences pending call
    final storedCallData = await FcmService.popPendingIncomingCallData();
    if (storedCallData != null) {
      if (isCallCancellationPayload(storedCallData)) {
        dismissIncomingCall(reason: 'Stored background call was cancelled');
        return;
      } else if (_isCallPayload(storedCallData) && !_hasIncomingCall) {
        final parsed = IncomingCallData.fromFcmData(storedCallData);
        if (parsed.isValid) {
          triggerIncomingCall(parsed);
          return;
        }
      }
    }

    // 3. Native Android Intent
    final nativeCallData = await FcmService.getPendingCallFromNative();
    if (nativeCallData != null) {
      if (isCallCancellationPayload(nativeCallData)) {
        dismissIncomingCall(reason: 'Native call intent was cancelled');
        return;
      } else if (_isCallPayload(nativeCallData) && !_hasIncomingCall) {
        final parsed = IncomingCallData.fromFcmData(nativeCallData);
        if (parsed.isValid) {
          triggerIncomingCall(parsed);
          return;
        }
      }
    }
  }

  Map<String, dynamic> _extractFullPayload(dynamic message) {
    final Map<String, dynamic> payload = {};
    if (message != null && message.data is Map) {
      payload.addAll(Map<String, dynamic>.from(message.data as Map));
    }
    if (message != null && message.notification != null) {
      if (!payload.containsKey('title') && message.notification!.title != null) {
        payload['title'] = message.notification!.title;
      }
      if (!payload.containsKey('body') && message.notification!.body != null) {
        payload['body'] = message.notification!.body;
      }
    }
    return payload;
  }

  bool _isCallPayload(Map<String, dynamic> data) {
    if (data.isEmpty) return false;
    if (isCallCancellationPayload(data)) return false;

    final status = data['status']?.toString().toLowerCase() ?? '';
    if (status == 'ended' ||
        status == 'completed' ||
        status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled' ||
        status == 'missed' ||
        status == 'finished') {
      return false;
    }

    final hasCallId = data['call_id'] != null ||
        data['callId'] != null ||
        data['callID'] != null ||
        data['id'] != null ||
        data['pk'] != null ||
        data['session_id'] != null;

    final channelName = data['channel_name']?.toString() ??
        data['channelName']?.toString() ??
        data['channel']?.toString() ??
        data['room']?.toString() ??
        data['agora_channel']?.toString() ??
        '';
    final hasValidChannel = channelName.trim().isNotEmpty;

    final title = data['title']?.toString().toLowerCase() ?? '';
    final body = data['body']?.toString().toLowerCase() ?? '';
    final type = data['type']?.toString().toLowerCase() ?? '';
    final action = data['action']?.toString().toLowerCase() ?? '';

    final isCallText = title.contains('call') ||
        body.contains('call') ||
        type.contains('call') ||
        type.contains('incoming') ||
        action.contains('call') ||
        action.contains('ring') ||
        status.contains('ringing') ||
        status.contains('pending') ||
        status.contains('requested');

    return hasCallId || hasValidChannel || isCallText;
  }

  /// Accepts the incoming call: builds a [CallModel] and opens [AudioCallScreen]
  Future<void> acceptCall(BuildContext context) async {
    if (_incomingCallData == null) return;

    final callData = _incomingCallData!;
    _isAccepting = true;
    notifyListeners();

    // Stop ringtone immediately
    await _agoraService.stopRingtone();

    String? agoraToken = callData.token;
    String channel = callData.channelName.isNotEmpty
        ? callData.channelName
        : (callData.callId > 0
            ? 'gabby_call_${callData.callId}'
            : AgoraConstants.generateChannelId(
                callerId: callData.callerName,
                agentId: 'agent',
              ));
    int effectiveUid = callData.uid;

    // Send 'accepted' status to server
    if (callData.callId > 0) {
      try {
        final res = await _updateCallStatusOnServer(
          callId: callData.callId,
          status: 'accepted',
        );
        if (res != null) {
          final resData = res['data'] is Map<String, dynamic>
              ? res['data'] as Map<String, dynamic>
              : res;
          final serverToken = resData['agora_token']?.toString() ??
              resData['token']?.toString() ??
              resData['agoraToken']?.toString() ??
              resData['rtc_token']?.toString();
          if (serverToken != null && serverToken.isNotEmpty) {
            agoraToken = serverToken;
          }
          final serverChannel = resData['channel_name']?.toString() ??
              resData['channelName']?.toString();
          if (serverChannel != null && serverChannel.isNotEmpty) {
            channel = serverChannel;
          }
          if (resData['uid'] != null) {
            final parsedUid = resData['uid'] is int
                ? resData['uid'] as int
                : int.tryParse(resData['uid'].toString()) ?? 0;
            if (parsedUid > 0) {
              effectiveUid = parsedUid;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [IncomingCallManager] Error updating call status: $e');
      }
    }

    if (effectiveUid <= 0) {
      final parts = channel.split('_');
      if (parts.length >= 4) {
        effectiveUid = int.tryParse(parts[3]) ?? 0;
      }
    }
    if (effectiveUid <= 0) {
      effectiveUid = 20000 + (callData.callId > 0 ? callData.callId : 1);
    }

    if (agoraToken == null || agoraToken.isEmpty) {
      agoraToken = AgoraConstants.generateRtcToken(
        channelName: channel,
        uid: effectiveUid,
      );
      debugPrint(
        '🔑 [IncomingCallManager] Generated Agora RTC Token for channel "$channel", UID $effectiveUid',
      );
    }

    final callModel = CallModel(
      callId: callData.callId.toString(),
      callerId: callData.callerName,
      callerName: callData.callerName,
      callerAvatar: callData.callerAvatar,
      receiverId: 'Listener',
      receiverName: 'Listener',
      channelId: channel,
      token: agoraToken,
      uid: effectiveUid,
      status: CallStatus.ringing,
      isOutgoing: false,
    );

    _incomingCallPollTimer?.cancel();
    _incomingCallPollTimer = null;
    _hasIncomingCall = false;
    _incomingCallData = null;
    _isAccepting = false;
    FcmService.cancelCallNotification(callData.callId);
    notifyListeners();

    final targetContext = NavigationService.currentContext ?? context;
    if (targetContext.mounted) {
      await AudioCallScreen.start(targetContext, callModel);
    }
  }

  /// Declines the incoming call, notifies backend of 'reject' status, and dismisses the alert.
  Future<void> declineCall() async {
    _incomingCallPollTimer?.cancel();
    _incomingCallPollTimer = null;
    await _agoraService.stopRingtone();

    final targetCallId = _incomingCallData?.callId;
    if (targetCallId != null) {
      FcmService.cancelCallNotification(targetCallId);
    }
    _hasIncomingCall = false;
    _incomingCallData = null;
    _isAccepting = false;
    notifyListeners();

    if (targetCallId != null && targetCallId > 0) {
      await _updateCallStatusOnServer(callId: targetCallId, status: 'reject');
    }
  }

  /// Dismisses an incoming ringing call when cancelled by caller or rejected
  void dismissIncomingCall({String? reason}) {
    _incomingCallPollTimer?.cancel();
    _incomingCallPollTimer = null;
    _agoraService.stopRingtone();

    final callId = _incomingCallData?.callId;
    if (callId != null) {
      FcmService.cancelCallNotification(callId);
    }
    _hasIncomingCall = false;
    _incomingCallData = null;
    _isAccepting = false;
    debugPrint('📞 [IncomingCallManager] Incoming call dismissed: $reason');
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _updateCallStatusOnServer({
    required int callId,
    required String status,
  }) async {
    try {
      final token = await TokenManager().getAccessToken() ??
          await TokenManager().getVerificationToken();
      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      String validStatus = status.toLowerCase().trim();
      if (validStatus == 'ended' || validStatus == 'finished') {
        validStatus = 'completed';
      } else if (validStatus == 'declined' || validStatus == 'rejected') {
        validStatus = 'reject';
      }

      final response = await _apiService.post(
        ApiConstants.updateCallStatus(callId),
        data: {'status': validStatus},
        options: options,
        requiresAuth: true,
      );

      if (response.isSuccess && response.rawData is Map) {
        return response.rawData as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ [IncomingCallManager] Error updating call status: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _incomingCallPollTimer?.cancel();
    _fcmCallSubscription?.cancel();
    _fcmTapSubscription?.cancel();
    _fcmNativeSubscription?.cancel();
    _fcmTokenSubscription?.cancel();
    super.dispose();
  }
}
