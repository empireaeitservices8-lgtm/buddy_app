import 'dart:async';
import 'package:buddy_app/core/constants/agora_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_response.dart';
import '../core/network/api_service.dart';
import '../core/network/token_manager.dart';
import '../core/services/agora_service.dart';
import '../core/services/fcm_service.dart';
import '../data/models/agent_dashboard_model.dart';
import '../data/models/agent_rating_model.dart';
import '../data/models/call_model.dart';
import '../data/models/incoming_call_data.dart';
import '../data/repositories/auth_repository.dart';
import 'base_view_model.dart';

class HandledSession {
  final String id;
  final String clientName;
  final String callType; // "Voice Call", "Video Call"
  final String duration;
  final int coinsEarned;
  final String timeAgo;

  const HandledSession({
    required this.id,
    required this.clientName,
    required this.callType,
    required this.duration,
    required this.coinsEarned,
    required this.timeAgo,
  });
}

class EarningsLedgerEntry {
  final String id;
  final String title;
  final String timestamp;
  final int coins;
  final bool isBonus;

  const EarningsLedgerEntry({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.coins,
    this.isBonus = false,
  });
}

class AgentDashboardViewModel extends BaseViewModel {
  final IAuthRepository _authRepository;
  final ApiService _apiService;
  final AgoraService _agoraService;

  int _activeTab = 0; // 0: Workbench, 1: Agent Form, 2: Earnings
  bool _isDutyOn = true;
  bool _isTogglingDuty = false;
  int? _activeDutySessionId;
  DateTime? _dutyStartedAt;

  // Agent Profile Stats
  String _agentName = 'Listener';
  // ignore: unused_field
  String _profession = 'Friendly Chat, Emotional Support';
  int _selectedRate = 5; // 5, 10, 15
  int _todayEarned = 0;
  int _totalCalls = 0;
  String _dutyTime = '0m';
  double _rating = 5.0;

  // Duty Form Configuration
  String _displayName = 'Listener';
  String _selectedProfession = 'Friendly Chat, Emotional Support';
  String _languages = 'English, Spanish';
  String _bio = '';

  // Active incoming call
  bool _hasIncomingCall = false;
  IncomingCallData? _incomingCallData;
  StreamSubscription? _fcmCallSubscription;
  StreamSubscription? _fcmTapSubscription;
  StreamSubscription? _fcmNativeSubscription;
  StreamSubscription? _fcmTokenSubscription;

  // Earnings
  int _totalCoinBalance = 0;

  String? _authToken;
  AgentProfileModel? _agentProfile;
  AgentRatingData? _ratingData;
  bool _isLoadingRating = false;
  AgentDashboardData? _dashboardData;
  List<String> _interests = [];
  String? _profilePicture;

  // Handled Sessions list
  final List<HandledSession> _handledSessions = [];

  // Earnings Ledger History
  final List<EarningsLedgerEntry> _earningsHistory = [];

  AgentDashboardViewModel({
    required IAuthRepository authRepository,
    ApiService? apiService,
    AgoraService? agoraService,
  }) : _authRepository = authRepository,
       _apiService = apiService ?? ApiService(),
       _agoraService = agoraService ?? AgoraService() {
    _isDutyOn = true; // Always ON by default when entering the screen
    final user = _authRepository.currentUser;
    if (user != null && user.firstName.isNotEmpty) {
      _agentName = user.firstName;
      _displayName = user.firstName;
      if (user.language != null && user.language!.isNotEmpty) {
        _languages = user.language!;
      }
    }
    init();
  }

  // Getters
  int get activeTab => _activeTab;
  bool get isDutyOn => _isDutyOn;
  bool get isTogglingDuty => _isTogglingDuty;
  int? get activeDutySessionId => _activeDutySessionId;
  DateTime? get dutyStartedAt => _dutyStartedAt;

  String get agentName => _displayName.isNotEmpty
      ? _displayName
      : (_agentName.isNotEmpty ? _agentName : 'Listener');
  String get profession => _selectedProfession;
  int get selectedRate => _selectedRate;
  int get todayEarned => _todayEarned;
  int get totalCalls => _totalCalls;
  String get dutyTime => _dutyTime;
  double get rating => _rating;

  String get displayName => _displayName.isNotEmpty
      ? _displayName
      : (_agentName.isNotEmpty ? _agentName : 'Listener');
  String get selectedProfession => _selectedProfession;
  String get languages => _languages;
  String get bio => _bio;
  List<String> get interests => _interests;
  String? get profilePicture => _profilePicture;
  AgentProfileModel? get agentProfile => _agentProfile;
  AgentRatingData? get ratingData => _ratingData;
  bool get isLoadingRating => _isLoadingRating;

  bool get hasIncomingCall => _hasIncomingCall;
  IncomingCallData? get incomingCallData => _incomingCallData;
  String get callerName => _incomingCallData?.callerName ?? 'Caller';
  String get callTopic => _incomingCallData?.category != null
      ? 'Topic: ${_incomingCallData!.category}'
      : 'Incoming Call';

  int get totalCoinBalance => _totalCoinBalance;
  String? get authToken => _authToken;
  AgoraService get agoraService => _agoraService;
  AgentDashboardData? get dashboardData => _dashboardData;
  List<HandledSession> get handledSessions => _handledSessions;
  List<EarningsLedgerEntry> get earningsHistory => _earningsHistory;

  Future<void> _loadAuthToken() async {
    final token =
        await _apiService.tokenManager.getAccessToken() ??
        _authRepository.verificationToken ??
        await _apiService.tokenManager.getVerificationToken();
    if (token != null && token.isNotEmpty) {
      _authToken = token;
      final current = await _apiService.tokenManager.getAccessToken();
      if (current == null || current.isEmpty) {
        await _apiService.tokenManager.saveTokens(accessToken: token);
      }
      debugPrint('🔑 [BEARER TOKEN]: Bearer $token');
      notifyListenersSafely();
    }
  }

  Future<bool> _ensureAgentRole() async {
    final role = await _apiService.tokenManager.getUserRole();
    if (role != null && role.toLowerCase() == 'user') {
      debugPrint('🛑 [AgentDashboard] Guard: Current account is a caller/user account. Suppressing agent API calls.');
      return false;
    }
    return true;
  }

  /// Initializes the dashboard: loads token, automatically turns ON duty, and fetches profile + dashboard data
  Future<void> init() async {
    if (!await _ensureAgentRole()) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      await _loadAuthToken();
      _listenForIncomingCalls();
      await syncFcmTokenToBackend();
      await turnOnDutyAuto();
      await Future.wait([
        fetchAgentProfile(),
        fetchDashboardData(),
      ]);
      // Check if the app was launched directly from an incoming call notification
      await checkPendingFcmCall();
    } finally {
      setLoading(false);
    }
  }

  /// Pull-to-refresh handler to re-fetch latest stats, duty state, earnings, and profile
  Future<void> refresh() async {
    await _loadAuthToken();
    await checkPendingFcmCall();
    await Future.wait([
      fetchAgentProfile(),
      fetchDashboardData(silent: true),
    ]);
  }

  /// Checks for any pending incoming call from FCM background/notification taps
  /// and syncs with backend when app is resumed from background.
  Future<void> checkPendingIncomingCallsAndRefresh() async {
    await checkPendingFcmCall();
    await fetchDashboardData(silent: true);
  }

  /// Checks and consumes any pending notification message from memory, SharedPreferences, or native Intent
  Future<void> checkPendingFcmCall() async {
    // 1. Check in-memory pending message
    final pendingMsg = FcmService.popPendingInitialMessage();
    if (pendingMsg != null) {
      final payload = _extractFullPayload(pendingMsg);
      if (_isCallCancellationPayload(payload)) {
        dismissIncomingCall(reason: 'Initial message was call cancellation');
        return;
      } else if (_isCallPayload(payload) && !_hasIncomingCall) {
        final parsed = IncomingCallData.fromFcmData(payload);
        if (parsed.isValid) {
          _incomingCallData = parsed;
          _hasIncomingCall = true;
          debugPrint(
            '📞 [AgentDashboard] Consumed background call notification: ${_incomingCallData!.callerName} (Call ID: ${_incomingCallData!.callId}, Channel: ${_incomingCallData!.channelName})',
          );
          notifyListenersSafely();
          return;
        }
      }
    }

    // 2. Check SharedPreferences for call stored by background isolate
    final storedCallData = await FcmService.popPendingIncomingCallData();
    if (storedCallData != null) {
      if (_isCallCancellationPayload(storedCallData)) {
        dismissIncomingCall(reason: 'Stored background call was cancelled');
        return;
      } else if (_isCallPayload(storedCallData) && !_hasIncomingCall) {
        final parsed = IncomingCallData.fromFcmData(storedCallData);
        if (parsed.isValid) {
          _incomingCallData = parsed;
          _hasIncomingCall = true;
          debugPrint(
            '📞 [AgentDashboard] Consumed background-isolate stored call: ${_incomingCallData!.callerName} (Call ID: ${_incomingCallData!.callId}, Channel: ${_incomingCallData!.channelName})',
          );
          notifyListenersSafely();
          return;
        }
      }
    }

    // 3. Check native Android Intent extras
    final nativeCallData = await FcmService.getPendingCallFromNative();
    if (nativeCallData != null) {
      if (_isCallCancellationPayload(nativeCallData)) {
        dismissIncomingCall(reason: 'Native call intent was cancelled');
        return;
      } else if (_isCallPayload(nativeCallData) && !_hasIncomingCall) {
        final parsed = IncomingCallData.fromFcmData(nativeCallData);
        if (parsed.isValid) {
          _incomingCallData = parsed;
          _hasIncomingCall = true;
          debugPrint(
            '📞 [AgentDashboard] Consumed native Android Intent call: ${_incomingCallData!.callerName} (Call ID: ${_incomingCallData!.callId})',
          );
          notifyListenersSafely();
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
    if (_isCallCancellationPayload(data)) return false;

    final type = data['type']?.toString().toLowerCase() ?? '';
    final action = data['action']?.toString().toLowerCase() ?? '';
    final status = data['status']?.toString().toLowerCase() ?? '';

    // Ignore ended or non-active statuses
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

  bool _isCallCancellationPayload(Map<String, dynamic> data) {
    if (data.isEmpty) return false;
    final type = data['type']?.toString().toLowerCase() ?? '';
    final action = data['action']?.toString().toLowerCase() ?? '';
    final status = data['status']?.toString().toLowerCase() ?? '';
    final title = data['title']?.toString().toLowerCase() ?? '';
    final body = data['body']?.toString().toLowerCase() ?? '';
    final reason = data['reason']?.toString().toLowerCase() ?? '';
    final event = data['event']?.toString().toLowerCase() ?? '';

    return type.contains('cancel') ||
        type.contains('reject') ||
        type.contains('decline') ||
        type.contains('end') ||
        type.contains('missed') ||
        type.contains('busy') ||
        type.contains('hangup') ||
        type.contains('cut') ||
        action.contains('cancel') ||
        action.contains('reject') ||
        action.contains('decline') ||
        action.contains('end') ||
        status.contains('cancel') ||
        status.contains('reject') ||
        status.contains('decline') ||
        status.contains('end') ||
        status.contains('completed') ||
        status.contains('missed') ||
        status.contains('finished') ||
        title.contains('reject') ||
        title.contains('cancel') ||
        title.contains('declined') ||
        title.contains('ended') ||
        title.contains('missed') ||
        title.contains('cut') ||
        body.contains('reject') ||
        body.contains('cancel') ||
        body.contains('declined') ||
        body.contains('ended') ||
        body.contains('missed') ||
        body.contains('cut') ||
        reason.contains('reject') ||
        reason.contains('cancel') ||
        event.contains('reject') ||
        event.contains('cancel') ||
        event.contains('end');
  }

  int? _lastHandledCallId;
  int _lastHandledCallTime = 0;

  bool _shouldHandleIncomingCall(int callId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastHandledCallId == callId && (now - _lastHandledCallTime) < 4000) {
      return false;
    }
    _lastHandledCallId = callId;
    _lastHandledCallTime = now;
    return true;
  }

  /// Subscribes to FCM foreground messages and notification taps
  /// to detect incoming call requests from the backend.
  void _listenForIncomingCalls() {
    _fcmCallSubscription?.cancel();
    _fcmTapSubscription?.cancel();
    _fcmNativeSubscription?.cancel();
    _fcmTokenSubscription?.cancel();

    // Foreground: FCM data message arrives while agent is on dashboard
    _fcmCallSubscription = FcmService.onMessageStream.listen((message) {
      final payload = _extractFullPayload(message);
      if (_isCallCancellationPayload(payload)) {
        final cancelCallId = int.tryParse(payload['call_id']?.toString() ?? payload['id']?.toString() ?? '');
        if (_hasIncomingCall && (cancelCallId == null || cancelCallId == _incomingCallData?.callId)) {
          dismissIncomingCall(reason: 'Caller cancelled call via FCM foreground');
        }
      } else if (_isCallPayload(payload)) {
        final parsed = IncomingCallData.fromFcmData(payload);
        if (parsed.isValid && _shouldHandleIncomingCall(parsed.callId)) {
          _incomingCallData = parsed;
          _hasIncomingCall = true;
          debugPrint(
            '📞 [AgentDashboard] Incoming call received via FCM foreground: ${_incomingCallData!.callerName} (ID: ${_incomingCallData!.callId}, Channel: ${_incomingCallData!.channelName})',
          );
          notifyListenersSafely();
        }
      }
    });

    // Background/terminated: agent tapped the notification
    _fcmTapSubscription = FcmService.onNotificationTapStream.listen((message) {
      final payload = _extractFullPayload(message);
      if (_isCallCancellationPayload(payload)) {
        final cancelCallId = int.tryParse(payload['call_id']?.toString() ?? payload['id']?.toString() ?? '');
        if (_hasIncomingCall && (cancelCallId == null || cancelCallId == _incomingCallData?.callId)) {
          dismissIncomingCall(reason: 'Caller cancelled call');
        }
      } else if (_isCallPayload(payload)) {
        final parsed = IncomingCallData.fromFcmData(payload);
        if (parsed.isValid && _shouldHandleIncomingCall(parsed.callId)) {
          _incomingCallData = parsed;
          _hasIncomingCall = true;
          debugPrint(
            '📞 [AgentDashboard] Notification tap → incoming call from: ${_incomingCallData!.callerName} (ID: ${_incomingCallData!.callId})',
          );
          notifyListenersSafely();
        }
      }
    });

    // Native Android Intent: incoming call received via system intent/channel
    _fcmNativeSubscription = FcmService.onNativeCallStream.listen((data) {
      if (_isCallCancellationPayload(data)) {
        final cancelCallId = int.tryParse(data['call_id']?.toString() ?? data['id']?.toString() ?? '');
        if (_hasIncomingCall && (cancelCallId == null || cancelCallId == _incomingCallData?.callId)) {
          dismissIncomingCall(reason: 'Caller cancelled call via Intent');
        }
      } else if (_isCallPayload(data)) {
        final parsed = IncomingCallData.fromFcmData(data);
        if (parsed.isValid && _shouldHandleIncomingCall(parsed.callId)) {
          _incomingCallData = parsed;
          _hasIncomingCall = true;
          debugPrint(
            '📞 [AgentDashboard] Native Android Intent → incoming call from: ${_incomingCallData!.callerName} (ID: ${_incomingCallData!.callId})',
          );
          notifyListenersSafely();
        }
      }
    });

    // Automatically sync new FCM tokens to backend
    _fcmTokenSubscription = FcmService.onTokenRefreshStream.listen((newToken) {
      debugPrint('🔄 [AgentDashboard] New FCM token received, syncing to backend: $newToken');
      syncFcmTokenToBackend(newToken);
    });
  }

  /// Fetches agent profile from agent/profile/ passing the Bearer token in Authorization header
  Future<void> fetchAgentProfile() async {
    if (!await _ensureAgentRole()) return;
    await _loadAuthToken();
    try {
      final options = _authToken != null && _authToken!.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $_authToken'})
          : null;

      final response = await _apiService.get(
        ApiConstants.agentProfile,
        options: options,
        requiresAuth: true,
      );

      if (response.isSuccess && response.rawData is Map) {
        final raw = response.rawData as Map<String, dynamic>;
        final dataJson = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : raw;

        debugPrint('🔍 [AgentDashboard] fetchAgentProfile payload: $dataJson');
        _agentProfile = AgentProfileModel.fromJson(dataJson);
        if (_agentProfile != null) {
          final p = _agentProfile!;
          if (p.displayName != null && p.displayName!.isNotEmpty) {
            _displayName = p.displayName!;
            _agentName = p.displayName!;
          } else if (p.name != null && p.name!.isNotEmpty) {
            _displayName = p.name!;
            _agentName = p.name!;
          } else if (p.username != null && p.username!.isNotEmpty) {
            _displayName = p.username!;
            _agentName = p.username!;
          }

          if (p.professionName != null && p.professionName!.isNotEmpty) {
            _selectedProfession = p.professionName!;
            _profession = p.professionName!;
          } else if (p.profession != null && p.profession!.isNotEmpty) {
            _selectedProfession = p.profession!;
            _profession = p.profession!;
          }

          if (p.bio != null) {
            _bio = p.bio!;
          }
          if (p.language != null && p.language!.isNotEmpty) {
            _languages = p.language!;
          }
          if (p.interests.isNotEmpty) {
            _interests = p.interests;
          }
          if (p.profilePictureUrl != null && p.profilePictureUrl!.isNotEmpty) {
            _profilePicture = p.profilePictureUrl;
          } else if (p.profilePicture != null && p.profilePicture!.isNotEmpty) {
            _profilePicture = p.profilePicture;
          }

          _selectedRate = p.ratePerSecond;
          _rating = p.rating;
          if (p.totalCalls > 0) {
            _totalCalls = p.totalCalls;
          }
          if (p.totalEarnedCoins > 0) {
            _todayEarned = p.totalEarnedCoins;
          }
          notifyListenersSafely();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AgentDashboard] fetchAgentProfile error: $e');
    }
  }

  /// No-op rating fetch (ratings are loaded via profile & dashboard payloads)
  Future<void> fetchAgentRating([dynamic targetAgentId]) async {
    // Suppressed: rating data comes directly from profile/dashboard APIs
    _isLoadingRating = false;
    notifyListenersSafely();
  }

  /// Automatically turns on duty when entering the screen
  Future<void> turnOnDutyAuto() async {
    if (!await _ensureAgentRole()) return;
    _isDutyOn = true;
    notifyListenersSafely();
    await setDutyStatus(true);
  }

  /// Sets duty status (ON or OFF) with agent auth token attached
  Future<void> setDutyStatus(bool turnOn) async {
    if (!await _ensureAgentRole()) return;
    if (_isTogglingDuty) return;
    _isTogglingDuty = true;
    _isDutyOn = turnOn;
    notifyListenersSafely();

    try {
      await _loadAuthToken();
      final endpoint = turnOn
          ? ApiConstants.agentDutyOn
          : ApiConstants.agentDutyOff;

      final options = _authToken != null && _authToken!.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $_authToken'})
          : null;

      final fcmToken = await FcmService.getFcmToken() ??
          await TokenManager().getFcmToken();

      final body = <String, dynamic>{
        'is_on_duty': turnOn,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      };

      debugPrint(
        '⚡ [AgentDashboard] Setting Duty Status: turnOn=$turnOn, endpoint=$endpoint, fcm_token=${fcmToken != null && fcmToken.isNotEmpty}',
      );

      ApiResponse response;
      try {
        response = await _apiService.post(
          endpoint,
          data: body,
          options: options,
          requiresAuth: true,
        );
      } catch (e) {
        debugPrint(
          '⚠️ [AgentDashboard] Dedicated endpoint $endpoint failed, falling back to agentDutyToggle: $e',
        );
        response = await _apiService.post(
          ApiConstants.agentDutyToggle,
          data: body,
          options: options,
          requiresAuth: true,
        );
      }

      if (response.rawData is Map) {
        final data = response.rawData as Map<String, dynamic>;
        if (data.containsKey('is_on_duty')) {
          _isDutyOn = data['is_on_duty'] == true;
        }
        if (data.containsKey('session_id') && data['session_id'] != null) {
          _activeDutySessionId = int.tryParse(data['session_id'].toString());
        }
        if (data.containsKey('started_at') && data['started_at'] != null) {
          _dutyStartedAt = DateTime.tryParse(data['started_at'].toString());
        }
        if (data.containsKey('today_duty_seconds') &&
            data['today_duty_seconds'] != null) {
          final seconds = (data['today_duty_seconds'] is num)
              ? (data['today_duty_seconds'] as num).toInt()
              : (int.tryParse(data['today_duty_seconds'].toString()) ?? 0);
          _dutyTime = _formatDutySeconds(seconds);
        } else if (data.containsKey('last_session_duration_seconds') &&
            data['last_session_duration_seconds'] != null) {
          final seconds = (data['last_session_duration_seconds'] is num)
              ? (data['last_session_duration_seconds'] as num).toInt()
              : (int.tryParse(
                      data['last_session_duration_seconds'].toString(),
                    ) ??
                    0);
          _dutyTime = _formatDutySeconds(seconds);
        }
        debugPrint(
          '✅ [AgentDashboard] Duty updated: isDutyOn=$_isDutyOn, sessionId=$_activeDutySessionId, dutyTime=$_dutyTime',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [AgentDashboardViewModel] Error updating duty status: $e');
    } finally {
      _isTogglingDuty = false;
      notifyListenersSafely();
    }
  }

  String _formatDutySeconds(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Loads full dashboard stats, duty status, calls, and earnings from agent/dashboard/
  Future<void> fetchDashboardData({bool silent = false}) async {
    if (!await _ensureAgentRole()) {
      if (!silent) setLoading(false);
      return;
    }
    await _loadAuthToken();
    if (!silent) setLoading(true);
    try {
      final options = _authToken != null && _authToken!.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $_authToken'})
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

        // Check if there is an active incoming call returned in dashboard payload
        if (!_hasIncomingCall && _isDutyOn) {
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
            final status = activeCallMap['status']?.toString().toLowerCase() ?? '';
            final isRinging = status.isEmpty ||
                status == 'pending' ||
                status == 'ringing' ||
                status == 'calling' ||
                status == 'requested' ||
                status == 'initiated';

            if (isRinging) {
              final parsed = IncomingCallData.fromFcmData(activeCallMap);
              if (parsed.isValid) {
                _incomingCallData = parsed;
                _hasIncomingCall = true;
                debugPrint(
                  '📞 [AgentDashboard] Active incoming call detected from dashboard sync: ${_incomingCallData!.callerName} (ID: ${_incomingCallData!.callId}, Channel: ${_incomingCallData!.channelName})',
                );
                notifyListenersSafely();
              }
            }
          }
        }

        _dashboardData = AgentDashboardData.fromJson(dataJson);

        if (_dashboardData != null) {
          final p = _dashboardData!.profile;
          final d = _dashboardData!.duty;
          final e = _dashboardData!.earnings;
          final c = _dashboardData!.calls;

          if (p != null) {
            final effectiveName =
                (p.displayName != null && p.displayName!.isNotEmpty)
                ? p.displayName!
                : ((p.name != null && p.name!.isNotEmpty)
                      ? p.name!
                      : ((p.username != null && p.username!.isNotEmpty)
                            ? p.username!
                            : 'Listener'));
            _agentName = effectiveName;
            _displayName = effectiveName;
            if (p.profession != null && p.profession!.isNotEmpty) {
              _profession = p.profession!;
              _selectedProfession = p.profession!;
            }
            if (p.bio != null) {
              _bio = p.bio!;
            }
            _selectedRate = p.ratePerSecond;
            _rating = p.rating;
          }

          if (d != null) {
            _dutyTime = d.formattedDutyTime;
          }

          if (e != null) {
            _todayEarned = e.todayCoins;
            _totalCoinBalance = e.walletBalance > 0
                ? e.walletBalance
                : e.lifetimeCoins;
          }

          if (c != null) {
            _totalCalls = c.lifetimeCount > 0 ? c.lifetimeCount : c.todayCount;
          }

          if (_dashboardData!.recentSessions.isNotEmpty) {
            _handledSessions.clear();
            _earningsHistory.clear();
            for (final s in _dashboardData!.recentSessions) {
              _handledSessions.add(
                HandledSession(
                  id: s.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  clientName: s.callerName ?? 'Caller',
                  callType: s.callType ?? 'Voice Call 📞',
                  duration: s.duration ?? '0s',
                  coinsEarned: s.coinsEarned,
                  timeAgo: s.timeAgo ?? 'Just now',
                ),
              );
              _earningsHistory.add(
                EarningsLedgerEntry(
                  id: s.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Call with ${s.callerName ?? "Caller"}',
                  timestamp: s.timeAgo ?? 'Just now',
                  coins: s.coinsEarned,
                  isBonus: false,
                ),
              );
            }
          }
        }
      }
    } catch (_) {
      // Graceful fallback to cached state
    } finally {
      setLoading(false);
      notifyListenersSafely();
    }
  }

  void setTab(int index) {
    _activeTab = index;
    notifyListenersSafely();
  }

  Future<void> toggleDuty() async {
    await setDutyStatus(!_isDutyOn);
  }

  /// Accepts the incoming call: builds and returns a [CallModel]
  /// for navigating directly to the AudioCallScreen via Agora, and notifies backend of 'accepted' status.
  Future<CallModel?> acceptCall() async {
    if (_incomingCallData == null) return null;

    final callData = _incomingCallData!;
    _totalCalls += 1;

    String? agoraToken = callData.token;
    String channel = callData.channelName.isNotEmpty
        ? callData.channelName
        : (callData.callId > 0
              ? 'gabby_call_${callData.callId}'
              : AgoraConstants.generateChannelId(
                  callerId: callData.callerName,
                  agentId: _agentProfile?.id.toString() ?? _agentName,
                ));
    int effectiveUid = callData.uid;

    // Send 'accepted' status to server and extract token/channel/uid if returned
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
        debugPrint('⚠️ [AgentDashboard] Error updating call status to accepted: $e');
      }
    }

    if (effectiveUid <= 0) {
      effectiveUid = _agentProfile?.userId != null && _agentProfile!.userId! > 0
          ? _agentProfile!.userId!
          : (_agentProfile?.id != null && _agentProfile!.id! > 0
              ? _agentProfile!.id!
              : 0);
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
        '🔑 [AgentDashboard] Generated Agora RTC Token for channel "$channel", UID $effectiveUid',
      );
    }

    debugPrint(
      '📞 [AgentDashboard] Launching AudioCallScreen: callId=${callData.callId}, caller=${callData.callerName}, channel=$channel, uid=$effectiveUid',
    );

    // Build CallModel for AudioCallScreen (incoming = isOutgoing: false)
    final callModel = CallModel(
      callId: callData.callId.toString(),
      callerId: callData.callerName,
      callerName: callData.callerName,
      callerAvatar: callData.callerAvatar,
      receiverId: _agentName,
      receiverName: _agentName,
      channelId: channel,
      token: agoraToken,
      uid: effectiveUid,
      status: CallStatus.ringing,
      isOutgoing: false,
    );

    _hasIncomingCall = false;
    _incomingCallData = null;
    FcmService.cancelCallNotification(callData.callId);
    notifyListenersSafely();
    return callModel;
  }

  /// Dismisses an incoming ringing call when cancelled by caller or rejected
  void dismissIncomingCall({String? reason}) {
    final callId = _incomingCallData?.callId;
    if (callId != null) {
      FcmService.cancelCallNotification(callId);
    }
    _hasIncomingCall = false;
    _incomingCallData = null;
    debugPrint('📞 [AgentDashboard] Incoming call dismissed: $reason');
    notifyListenersSafely();
  }

  /// Declines the incoming call, notifies backend of 'rejected' status, and dismisses the alert.
  Future<void> declineCall() async {
    final callId = _incomingCallData?.callId;
    if (callId != null) {
      FcmService.cancelCallNotification(callId);
    }
    _hasIncomingCall = false;
    _incomingCallData = null;
    notifyListenersSafely();

    if (callId != null && callId > 0) {
      await _updateCallStatusOnServer(callId: callId, status: 'rejected');
    }
  }

  Future<Map<String, dynamic>?> _updateCallStatusOnServer({
    required int callId,
    required String status,
  }) async {
    try {
      await _loadAuthToken();
      final options = _authToken != null && _authToken!.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $_authToken'})
          : null;

      String validStatus = status.toLowerCase().trim();
      if (validStatus == 'ended' || validStatus == 'finished') {
        validStatus = 'completed';
      } else if (validStatus == 'declined') {
        validStatus = 'rejected';
      }

      final response = await _apiService.post(
        ApiConstants.updateCallStatus(callId),
        data: {'status': validStatus},
        options: options,
        requiresAuth: true,
      );
      debugPrint(
        '📞 [AgentDashboard] Call status updated: call_id=$callId, status=$validStatus, res=${response.rawData}',
      );
      if (response.isSuccess && response.rawData is Map) {
        return response.rawData as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint(
        '⚠️ [AgentDashboard] Failed to update call status ($status) for call $callId: $e',
      );
    }
    return null;
  }

  void setDisplayName(String value) {
    _displayName = value;
    notifyListenersSafely();
  }

  void setProfession(String value) {
    _selectedProfession = value;
    notifyListenersSafely();
  }

  void setSelectedRate(int rate) {
    _selectedRate = rate;
    notifyListenersSafely();
  }

  void setLanguages(String value) {
    _languages = value;
    notifyListenersSafely();
  }

  void setBio(String value) {
    _bio = value;
    notifyListenersSafely();
  }

  /// Submits the custom duty settings form to agent/duty-form/
  Future<bool> submitDutyForm() async {
    if (!await _ensureAgentRole()) return false;
    setLoading(true);
    clearError();
    try {
      final options = _authToken != null && _authToken!.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $_authToken'})
          : null;

      final fcmToken = await FcmService.getFcmToken() ??
          await TokenManager().getFcmToken();

      await _apiService.post(
        ApiConstants.agentDutyForm,
        data: {
          'name': _displayName.trim(),
          'profession': _selectedProfession.trim(),
          'rate_per_second': _selectedRate,
          'languages': _languages.trim(),
          'bio': _bio.trim(),
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        },
        options: options,
        requiresAuth: true,
      );
      _agentName = _displayName.isNotEmpty ? _displayName : _agentName;
      _profession = _selectedProfession;
      setLoading(false);
      notifyListenersSafely();
      return true;
    } catch (_) {
      _agentName = _displayName.isNotEmpty ? _displayName : _agentName;
      setLoading(false);
      notifyListenersSafely();
      return true;
    }
  }

  /// Proactively pushes the current FCM device token to all backend agent/user profile endpoints
  Future<void> syncFcmTokenToBackend([String? token]) async {
    try {
      final fcmToken = token ??
          await FcmService.getFcmToken() ??
          await TokenManager().getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      await _loadAuthToken();
      final options = _authToken != null && _authToken!.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $_authToken'})
          : null;

      final body = <String, dynamic>{
        'fcm_token': fcmToken,
      };

      // 0. Sync directly via api/fcm-token/
      try {
        await FcmService.sendFcmTokenToBackend(fcmToken);
      } catch (_) {}

      // 1. Sync via agent duty on/toggle
      try {
        await _apiService.post(
          ApiConstants.agentDutyOn,
          data: {'is_on_duty': _isDutyOn, ...body},
          options: options,
          requiresAuth: true,
        );
      } catch (_) {
        try {
          await _apiService.post(
            ApiConstants.agentDutyToggle,
            data: {'is_on_duty': _isDutyOn, ...body},
            options: options,
            requiresAuth: true,
          );
        } catch (_) {}
      }

      // 2. Sync via agent profile
      try {
        await _apiService.patch(
          ApiConstants.agentProfile,
          data: body,
          options: options,
          requiresAuth: true,
        );
      } catch (_) {}

      debugPrint('🔑 [AgentDashboard] Synced FCM token to backend: $fcmToken');
    } catch (e) {
      debugPrint('ℹ️ [AgentDashboard] FCM sync warning: $e');
    }
  }

  /// Alias for submitDutyForm
  Future<bool> saveDutyForm() => submitDutyForm();


  /// Submits a payout request to agent/request-payout/
  Future<bool> requestPayout({int? amount}) async {
    final payoutAmount = amount ?? _totalCoinBalance;
    if (payoutAmount < 5000) {
      setError('Minimum 5,000 coins required to request a payout.');
      return false;
    }

    try {
      await _loadAuthToken();
      final options = _authToken != null && _authToken!.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $_authToken'})
          : null;

      final response = await _apiService.post(
        ApiConstants.requestPayout,
        data: {'coins': payoutAmount, 'amount': payoutAmount},
        options: options,
        requiresAuth: true,
      );

      if (response.isSuccess) {
        await fetchDashboardData(silent: true);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [AgentDashboard] Failed to request payout: $e');
    }
    return false;
  }

  Future<void> logout() async {
    setLoading(true);
    _fcmCallSubscription?.cancel();
    _fcmTapSubscription?.cancel();
    _fcmNativeSubscription?.cancel();
    _fcmTokenSubscription?.cancel();

    // 1. Call the offline API to mark agent as offline on server before logging out
    try {
      await setDutyStatus(false);
    } catch (e) {
      debugPrint('⚠️ [AgentDashboard] Failed to set duty OFF during logout: $e');
    }

    try {
      await _agoraService.leaveCall();
    } catch (_) {}
    try {
      await _authRepository.logout();
    } catch (_) {}
    try {
      await TokenManager().clearTokens();
    } catch (_) {}
    setLoading(false);
  }

  @override
  void dispose() {
    _fcmCallSubscription?.cancel();
    _fcmTapSubscription?.cancel();
    _fcmNativeSubscription?.cancel();
    _fcmTokenSubscription?.cancel();
    super.dispose();
  }
}
