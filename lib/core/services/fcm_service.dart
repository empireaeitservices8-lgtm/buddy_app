import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../constants/api_constants.dart';
import '../network/token_manager.dart';
import 'agora_service.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel
_incomingCallsChannel = AndroidNotificationChannel(
  'incoming_calls_channel_v2',
  'Incoming Audio Calls',
  description:
      'High priority notifications for incoming audio calls with ringtone',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
  audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
);

const AndroidNotificationChannel
_messagesChannel = AndroidNotificationChannel(
  'messages_channel_v2',
  'Messages & Updates',
  description:
      'Standard notifications for text messages, alerts, and call status updates',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  showBadge: true,
  audioAttributesUsage: AudioAttributesUsage.notification,
);

/// Helper to determine if a push payload represents a call cancellation, rejection, or end event.
bool isCallCancellationPayload(
  Map<String, dynamic> data, {
  String? title,
  String? body,
}) {
  if (data.isEmpty && (title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return false;
  }
  final type = data['type']?.toString().toLowerCase() ?? '';
  final action = data['action']?.toString().toLowerCase() ?? '';
  final status = data['status']?.toString().toLowerCase() ?? '';
  final t = (data['title']?.toString() ?? title ?? '').toLowerCase();
  final b = (data['body']?.toString() ?? body ?? '').toLowerCase();
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
      t.contains('reject') ||
      t.contains('cancel') ||
      t.contains('declined') ||
      t.contains('ended') ||
      t.contains('missed') ||
      t.contains('cut') ||
      b.contains('reject') ||
      b.contains('cancel') ||
      b.contains('declined') ||
      b.contains('ended') ||
      b.contains('missed') ||
      b.contains('cut') ||
      reason.contains('reject') ||
      reason.contains('cancel') ||
      event.contains('reject') ||
      event.contains('cancel') ||
      event.contains('end');
}

/// Top-level background message handler for Firebase Cloud Messaging.
/// Must be annotated with @pragma('vm:entry-point') to work in the background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint(
    '🔔 [FCM Background] Received message: ${message.messageId} | notification: ${message.notification?.title} | data: ${message.data}',
  );

  // Unpack any stringified/nested JSON payload
  final Map<String, dynamic> data = {};
  if (message.data.isNotEmpty) {
    data.addAll(message.data);
    for (final key in [
      'data',
      'call',
      'payload',
      'message',
      'custom',
      'notification',
    ]) {
      if (data[key] is String && (data[key] as String).trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(data[key] as String);
          if (decoded is Map) {
            data.addAll(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      } else if (data[key] is Map) {
        data.addAll(Map<String, dynamic>.from(data[key] as Map));
      }
    }
  }

  if (message.notification != null) {
    if (!data.containsKey('title') && message.notification!.title != null) {
      data['title'] = message.notification!.title;
    }
    if (!data.containsKey('body') && message.notification!.body != null) {
      data['body'] = message.notification!.body;
    }
  }

  // 1. Check if this is a cancellation / rejection / end of call
  final isCancelled = isCallCancellationPayload(
    data,
    title: message.notification?.title,
    body: message.notification?.body,
  );

  if (isCancelled) {
    debugPrint('🛑 [FCM Background] Call was cancelled/rejected/ended: $data');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_incoming_call_data');
    } catch (_) {}

    try {
      final callId = int.tryParse(
        data['call_id']?.toString() ?? data['id']?.toString() ?? '',
      ) ?? 0;
      if (callId > 0) {
        await _localNotifications.cancel(callId);
      } else {
        await _localNotifications.cancelAll();
      }
    } catch (_) {}
    return;
  }

  // 2. Persist legitimate incoming call payload to SharedPreferences
  if (data.isNotEmpty) {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_incoming_call_data', jsonEncode(data));
      debugPrint(
        '💾 [FCM Background] Saved incoming call payload to SharedPreferences: $data',
      );
    } catch (e) {
      debugPrint('⚠️ [FCM Background] Error saving to SharedPreferences: $e');
    }

    // 3. Trigger high-priority heads-up local notification on Android
    try {
      final type = data['type']?.toString().toLowerCase() ?? '';
      final action = data['action']?.toString().toLowerCase() ?? '';
      final status = data['status']?.toString().toLowerCase() ?? '';
      final title = data['title']?.toString().toLowerCase() ?? '';
      final body = data['body']?.toString().toLowerCase() ?? '';

      final isCall =
          type.contains('call') ||
          type.contains('incoming') ||
          action.contains('call') ||
          status.contains('ringing') ||
          status.contains('pending') ||
          title.contains('call') ||
          body.contains('call') ||
          data['call_id'] != null ||
          data['callId'] != null ||
          data['id'] != null ||
          data['channel_name'] != null ||
          data['channel'] != null;

      // Initialize local notifications in the background isolate
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      // Explicitly create notification channels on Android OS
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_incomingCallsChannel);
      await androidPlugin?.createNotificationChannel(_messagesChannel);

      if (isCall) {
        final rawCaller =
            data['caller_name']?.toString() ??
            data['callerName']?.toString() ??
            data['caller']?.toString() ??
            data['name']?.toString() ??
            data['client_name']?.toString() ??
            data['user_name']?.toString() ??
            '';

        final callerName = (rawCaller.isNotEmpty &&
                !rawCaller.toLowerCase().contains('call') &&
                !rawCaller.toLowerCase().contains('reject') &&
                !rawCaller.toLowerCase().contains('notification'))
            ? rawCaller
            : 'Caller';

        final callId =
            int.tryParse(
              data['call_id']?.toString() ?? data['id']?.toString() ?? '',
            ) ??
            (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) % 100000;

        const androidDetails = AndroidNotificationDetails(
          'incoming_calls_channel_v2',
          'Incoming Audio Calls',
          channelDescription:
              'High priority notifications for incoming audio calls with ringtone',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          playSound: true,
          enableVibration: true,
          ongoing: true,
          autoCancel: true,
        );

        const details = NotificationDetails(android: androidDetails);
        await _localNotifications.show(
          callId,
          '📞 Incoming Audio Call',
          '$callerName is calling you. Tap to answer.',
          details,
          payload: jsonEncode(data),
        );
        debugPrint(
          '🔔 [FCM Background] Displayed Heads-Up Notification for $callerName (Call ID: $callId)',
        );
      } else if ((title.isNotEmpty || body.isNotEmpty) && message.notification == null) {
        // Only show local notification if Firebase SDK didn't already display a notification payload
        final notifId =
            (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) % 100000;

        const standardDetails = AndroidNotificationDetails(
          'messages_channel_v2',
          'Messages & Updates',
          channelDescription:
              'Standard notifications for text messages, alerts, and call status updates',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
        );

        await _localNotifications.show(
          notifId,
          data['title']?.toString() ?? 'Notification',
          data['body']?.toString() ?? '',
          const NotificationDetails(android: standardDetails),
          payload: jsonEncode(data),
        );
        debugPrint(
          '🔔 [FCM Background] Displayed Standard Message Notification: ${data['title']} - ${data['body']}',
        );
      }
    } catch (notifErr) {
      debugPrint(
        '⚠️ [FCM Background] Error showing heads-up notification: $notifErr',
      );
    }
  }
}

/// Centralized Firebase Cloud Messaging (FCM) Service.
/// Handles initialization, permission requests, token generation/refresh,
/// and message listeners (foreground, background, and notification tap).
class FcmService {
  FcmService._();

  static bool _isInitialized = false;
  static String? _cachedToken;
  static RemoteMessage? _pendingInitialMessage;

  static const MethodChannel _callChannel = MethodChannel(
    'com.gabby.talk/call_channel',
  );

  static final Map<String, int> _recentNotifications = {};

  static bool _isDuplicateNotification(String key, {int throttleMs = 3500}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _recentNotifications[key];
    if (lastTime != null && (now - lastTime) < throttleMs) {
      return true;
    }
    _recentNotifications[key] = now;
    if (_recentNotifications.length > 50) {
      _recentNotifications.removeWhere((_, time) => now - time > 30000);
    }
    return false;
  }

  /// Stream controller for incoming native intent calls
  static final StreamController<Map<String, dynamic>> _onNativeCallController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onNativeCallStream =>
      _onNativeCallController.stream;

  /// Returns and clears any pending message received while the app was in background or terminated
  static RemoteMessage? popPendingInitialMessage() {
    final msg = _pendingInitialMessage;
    _pendingInitialMessage = null;
    return msg;
  }

  /// Retrieves and clears any pending incoming call payload saved to SharedPreferences by the background isolate
  static Future<Map<String, dynamic>?> popPendingIncomingCallData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('pending_incoming_call_data');
      if (dataStr != null && dataStr.isNotEmpty) {
        await prefs.remove('pending_incoming_call_data');
        final decoded = jsonDecode(dataStr);
        if (decoded is Map<String, dynamic>) {
          debugPrint(
            '📦 [FcmService] Popped pending call from SharedPreferences: $decoded',
          );
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FcmService] Error reading pending call: $e');
    }
    return null;
  }

  /// Retrieves any pending call directly from native Android intent extras
  static Future<Map<String, dynamic>?> getPendingCallFromNative() async {
    try {
      final res = await _callChannel.invokeMethod<String>('getPendingCall');
      if (res != null && res.isNotEmpty) {
        final decoded = jsonDecode(res);
        if (decoded is Map<String, dynamic>) {
          debugPrint(
            '📱 [FcmService] Popped pending call from native Intent: $decoded',
          );
          return decoded;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Stream controller for incoming foreground messages
  static final StreamController<RemoteMessage> _onMessageController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onMessageStream =>
      _onMessageController.stream;

  /// Stream controller for notification open events (when user taps a notification)
  static final StreamController<RemoteMessage> _onNotificationTapController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onNotificationTapStream =>
      _onNotificationTapController.stream;

  /// Stream controller for new or refreshed FCM device tokens
  static final StreamController<String> _onTokenRefreshController =
      StreamController<String>.broadcast();
  static Stream<String> get onTokenRefreshStream =>
      _onTokenRefreshController.stream;

  /// Initializes Firebase Core and FCM configurations.
  /// Should be called during app startup (e.g., in `main()` or Splash screen).
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase with platform options
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (initErr) {
        // If already initialized, fallback to default instance
        debugPrint('ℹ️ [FCM] Firebase initializeApp note: $initErr');
      }
      debugPrint('🔥 [FCM] Firebase initialized successfully');

      // 2. Set Background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request Notification Permissions via permission_handler & FirebaseMessaging
      try {
        final permStatus = await Permission.notification.status;
        if (!permStatus.isGranted) {
          await Permission.notification.request();
        }
      } catch (permErr) {
        debugPrint('ℹ️ [FCM] PermissionHandler note: $permErr');
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}',
      );

      // 4. Foreground presentation options (suppress OS heads-up while app is open)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      // 5. Fetch & persist FCM Token
      final initialToken = await refreshToken();
      if (initialToken != null && initialToken.isNotEmpty) {
        _onTokenRefreshController.add(initialToken);
        unawaited(sendFcmTokenToBackend(initialToken));
      }

      // 6. Listen for token refresh events
      messaging.onTokenRefresh.listen((newToken) async {
        _cachedToken = newToken;
        await TokenManager().saveFcmToken(newToken);
        _onTokenRefreshController.add(newToken);
        debugPrint('🔄 [FCM] Token refreshed: $newToken');
        await sendFcmTokenToBackend(newToken);
      });

      // 7. Listen for Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('========== FCM MESSAGE ==========');
        debugPrint('Message ID: ${message.messageId}');
        debugPrint('Notification: ${message.notification}');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
        debugPrint('DATA: ${message.data}');
        debugPrint('=================================');

        debugPrint(
          '📨 [FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}',
        );
        debugPrint('📦 [FCM Foreground Data]: ${message.data}');
        _onMessageController.add(message);

        // In foreground, the in-app UI handles the incoming call/screen directly.
        // If this message represents a cancellation, cancel any active notification.
        final Map<String, dynamic> data = {};
        if (message.data.isNotEmpty) {
          data.addAll(message.data);
          for (final key in [
            'data',
            'call',
            'payload',
            'message',
            'custom',
            'notification',
          ]) {
            if (data[key] is String &&
                (data[key] as String).trim().startsWith('{')) {
              try {
                final decoded = jsonDecode(data[key] as String);
                if (decoded is Map) {
                  data.addAll(Map<String, dynamic>.from(decoded));
                }
              } catch (_) {}
            } else if (data[key] is Map) {
              data.addAll(Map<String, dynamic>.from(data[key] as Map));
            }
          }
        }
        if (isCallCancellationPayload(
          data,
          title: message.notification?.title,
          body: message.notification?.body,
        )) {
          final callId =
              int.tryParse(
                data['call_id']?.toString() ?? data['id']?.toString() ?? '',
              ) ?? 0;
          await AgoraService().stopRingtone();
          await cancelCallNotification(callId);
        }
      });

      // 8. Listen when app is opened from a background notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '🚀 [FCM OpenedApp] User tapped notification: ${message.data}',
        );
        _pendingInitialMessage = message;
        _onNotificationTapController.add(message);
      });

      // 9. Check if app was opened from a terminated state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '🚀 [FCM InitialMessage] App launched from terminated state: ${initialMessage.data}',
        );
        _pendingInitialMessage = initialMessage;
        _onNotificationTapController.add(initialMessage);
      }

      // 10. Initialize Local Notifications Plugin on main isolate
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final map = jsonDecode(payload) as Map<String, dynamic>;
              debugPrint('📞 [FcmService] Notification tapped payload: $map');
              _onNativeCallController.add(map);
            } catch (_) {}
          }
        },
      );

      // Create notification channels on Android OS
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_incomingCallsChannel);
      await androidPlugin?.createNotificationChannel(_messagesChannel);

      // Check if app was launched directly by tapping a local notification
      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final map = jsonDecode(payload) as Map<String, dynamic>;
            debugPrint(
              '🚀 [FcmService] App launched from local notification tap: $map',
            );
            _onNativeCallController.add(map);
          } catch (_) {}
        }
      }

      // 11. Listen for native Android incoming call intents
      _callChannel.setMethodCallHandler((call) async {
        if (call.method == 'onIncomingCallFromNative') {
          final arg = call.arguments;
          if (arg is String && arg.isNotEmpty) {
            try {
              final map = jsonDecode(arg) as Map<String, dynamic>;
              debugPrint('📞 [FcmService] Received native call intent: $map');
              _onNativeCallController.add(map);
            } catch (_) {}
          }
        }
      });

      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('⚠️ [FCM] Initialization error: $e');
      debugPrint('$stackTrace');
    }
  }

  /// Displays high-priority incoming call heads-up notification
  static Future<void> showIncomingCallNotification(
    Map<String, dynamic> data, {
    String? fallbackTitle,
    String? fallbackBody,
  }) async {
    try {
      final isCancelled = isCallCancellationPayload(
        data,
        title: fallbackTitle,
        body: fallbackBody,
      );

      final callId =
          int.tryParse(
            data['call_id']?.toString() ?? data['id']?.toString() ?? '',
          ) ?? 0;

      if (isCancelled) {
        debugPrint('🛑 [FcmService] Call cancelled or ended in foreground: $data');
        await AgoraService().stopRingtone();
        if (callId > 0) {
          await cancelCallNotification(callId);
        } else {
          await cancelCallNotification(0);
        }
        return;
      }

      final type = data['type']?.toString().toLowerCase() ?? '';
      final action = data['action']?.toString().toLowerCase() ?? '';
      final status = data['status']?.toString().toLowerCase() ?? '';
      final title =
          data['title']?.toString().toLowerCase() ??
          fallbackTitle?.toLowerCase() ??
          '';
      final body =
          data['body']?.toString().toLowerCase() ??
          fallbackBody?.toLowerCase() ??
          '';

      final isCall =
          type.contains('call') ||
          type.contains('incoming') ||
          action.contains('call') ||
          status.contains('ringing') ||
          status.contains('pending') ||
          title.contains('call') ||
          body.contains('call') ||
          data['call_id'] != null ||
          data['callId'] != null ||
          data['id'] != null ||
          data['channel_name'] != null ||
          data['channel'] != null;

      // Check user role: Only agents receive incoming audio call heads-up notifications
      final userRole = await TokenManager().getUserRole();
      final isAgent = userRole?.toLowerCase() == 'agent';

      if (!isAgent) {
        debugPrint(
          'ℹ️ [FcmService] Current user is not an agent (role: $userRole). Suppressed incoming audio call heads-up notification.',
        );
        if (!isCall) {
          final displayTitle =
              data['title']?.toString() ?? fallbackTitle ?? 'Notification';
          final displayBody = data['body']?.toString() ?? fallbackBody ?? '';
          final notifKey = 'notif_${displayTitle}_$displayBody';
          if (_isDuplicateNotification(notifKey)) {
            debugPrint('⏭️ [FcmService] Suppressed duplicate standard notification: $displayTitle');
            return;
          }
          final notifId = DateTime.now().millisecondsSinceEpoch % 100000;

          const standardDetails = AndroidNotificationDetails(
            'messages_channel_v2',
            'Messages & Updates',
            channelDescription:
                'Standard notifications for text messages, alerts, and call status updates',
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
          );

          await _localNotifications.show(
            notifId,
            displayTitle,
            displayBody,
            const NotificationDetails(android: standardDetails),
            payload: jsonEncode(data),
          );
          debugPrint(
            '🔔 [FcmService] Displayed Foreground Notification: $displayTitle - $displayBody',
          );
        }
        return;
      }

      if (!isCall) {
        final displayTitle =
            data['title']?.toString() ?? fallbackTitle ?? 'Notification';
        final displayBody = data['body']?.toString() ?? fallbackBody ?? '';
        final notifKey = 'notif_${displayTitle}_$displayBody';
        if (_isDuplicateNotification(notifKey)) {
          debugPrint('⏭️ [FcmService] Suppressed duplicate standard notification: $displayTitle');
          return;
        }
        final notifId = DateTime.now().millisecondsSinceEpoch % 100000;

        const standardDetails = AndroidNotificationDetails(
          'messages_channel_v2',
          'Messages & Updates',
          channelDescription:
              'Standard notifications for text messages, alerts, and call status updates',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
        );

        await _localNotifications.show(
          notifId,
          displayTitle,
          displayBody,
          const NotificationDetails(android: standardDetails),
          payload: jsonEncode(data),
        );
        debugPrint(
          '🔔 [FcmService] Displayed Foreground Notification: $displayTitle - $displayBody',
        );
        return;
      }

      final rawCaller =
          data['caller_name']?.toString() ??
          data['callerName']?.toString() ??
          data['caller']?.toString() ??
          data['name']?.toString() ??
          data['client_name']?.toString() ??
          data['user_name']?.toString() ??
          '';

      final callerName = (rawCaller.isNotEmpty &&
              !rawCaller.toLowerCase().contains('call') &&
              !rawCaller.toLowerCase().contains('reject') &&
              !rawCaller.toLowerCase().contains('notification'))
          ? rawCaller
          : 'Caller';

      final effectiveCallId =
          callId > 0 ? callId : (DateTime.now().millisecondsSinceEpoch % 100000);

      final callKey = 'call_${effectiveCallId}_$callerName';
      if (_isDuplicateNotification(callKey)) {
        debugPrint('⏭️ [FcmService] Suppressed duplicate call notification: $callKey');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'incoming_calls_channel_v2',
        'Incoming Audio Calls',
        channelDescription:
            'High priority notifications for incoming audio calls with ringtone',
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
        playSound: true,
        enableVibration: true,
        ongoing: true,
        autoCancel: true,
      );

      const details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        callId,
        '📞 Incoming Audio Call',
        '$callerName is calling you. Tap to answer.',
        details,
        payload: jsonEncode(data),
      );
      debugPrint(
        '🔔 [FcmService] Displayed Heads-Up Notification for $callerName (Call ID: $callId)',
      );
    } catch (e) {
      debugPrint('⚠️ [FcmService] Error showing heads-up notification: $e');
    }
  }

  /// Cancels an active incoming call notification from status bar
  static Future<void> cancelCallNotification(dynamic callId) async {
    try {
      final id = (callId is int)
          ? callId
          : (int.tryParse(callId.toString()) ?? 0);
      if (id > 0) {
        await _localNotifications.cancel(id);
      } else {
        await _localNotifications.cancelAll();
      }
    } catch (_) {}
  }

  /// Sends the fresh FCM device token to the backend API endpoint (`POST https://buddy2026.pythonanywhere.com/api/fcm-token/`).
  /// Requires an authenticated user session (Bearer token).
  static Future<bool> sendFcmTokenToBackend([String? token]) async {
    try {
      final fcmToken = token ?? await getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ [FcmService] FCM token is empty, skipping backend sync.');
        return false;
      }

      final accessToken = await TokenManager().getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint(
          'ℹ️ [FcmService] No active user access token found, saved FCM token locally for later sync.',
        );
        return false;
      }

      final fullUrl = ApiConstants.fullUrl(ApiConstants.fcmToken);
      debugPrint(
        '📤 [FcmService] Sending fresh FCM token to backend: $fullUrl (token: ${fcmToken.substring(0, fcmToken.length > 10 ? 10 : fcmToken.length)}...)',
      );

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dio.post(
        fullUrl,
        data: {'fcm_token': fcmToken},
      );

      debugPrint(
        '📥 [FcmService] Backend FCM token sync response [${response.statusCode}]: ${response.data}',
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      debugPrint('⚠️ [FcmService] Failed to send FCM token to backend: $e');
      return false;
    }
  }

  /// Refreshes the FCM token from Firebase and synchronizes it with the backend.
  /// When [forceNew] is true (e.g. after receiving a NotRegistered or invalid token error),
  /// it deletes the old cached Firebase instance token first to force Firebase to issue a fresh token.
  static Future<String?> refreshAndSyncToken({bool forceNew = false}) async {
    try {
      if (forceNew) {
        debugPrint(
          '🔄 [FcmService] NotRegistered/invalid token detected. Forcing token deletion & regeneration...',
        );
        try {
          await FirebaseMessaging.instance.deleteToken();
          _cachedToken = null;
          await TokenManager().saveFcmToken('');
        } catch (delErr) {
          debugPrint('⚠️ [FcmService] Error deleting old FCM token: $delErr');
        }
      }

      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        _cachedToken = newToken;
        await TokenManager().saveFcmToken(newToken);
        _onTokenRefreshController.add(newToken);
        debugPrint('🔑 [FcmService] Fresh FCM token acquired: $newToken');

        // Send to backend
        await sendFcmTokenToBackend(newToken);
        return newToken;
      }
    } catch (e) {
      debugPrint('⚠️ [FcmService] Error in refreshAndSyncToken: $e');
    }
    return null;
  }

  /// Refreshes and returns the FCM Device Token with retry mechanism.
  static Future<String?> refreshToken({int retries = 3}) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _cachedToken = token;
          await TokenManager().saveFcmToken(token);
          debugPrint('🔑 [FCM Token Success]: $token');
          return token;
        }
      } catch (e) {
        debugPrint('⚠️ [FCM] Token fetch attempt $attempt/$retries failed: $e');
        if (attempt < retries) {
          // Wait before retrying (e.g. 1.5s, 3s)
          await Future.delayed(Duration(milliseconds: 1500 * attempt));
        }
      }
    }
    return null;
  }

  /// Returns the current FCM token (from memory, TokenManager, or directly from Firebase).
  static Future<String?> getFcmToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    final savedToken = await TokenManager().getFcmToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      _cachedToken = savedToken;
      return savedToken;
    }
    return await refreshToken(retries: 2);
  }

  /// Synchronous getter if token was already loaded in memory
  static String? get cachedToken => _cachedToken ?? TokenManager().fcmTokenSync;

  /// Deletes the FCM token (e.g. on full account disconnect)
  static Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      _cachedToken = null;
      debugPrint('🗑️ [FCM] Device token deleted');
    } catch (e) {
      debugPrint('⚠️ [FCM] Error deleting token: $e');
    }
  }
}
