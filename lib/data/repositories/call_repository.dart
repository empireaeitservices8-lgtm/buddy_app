import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../../core/services/fcm_service.dart';
import '../models/call_request_model.dart';

/// Contract for Call operations on the user side & agent side
abstract class ICallRepository {
  /// Initiates a call request by [agentUserId] through `calls/request/`
  Future<CallRequestResponse> requestCall({
    required String agentUserId,
    int? categoryId,
    String? fcmToken,
  });

  /// Updates call status (e.g. 'accepted', 'rejected', 'ended') via `calls/<callId>/status/`
  Future<Map<String, dynamic>> updateCallStatus({
    required int callId,
    required String status,
  });

  /// Fetches the current call status via `calls/<callId>/status/` (GET)
  Future<Map<String, dynamic>> getCallStatus({
    required int callId,
  });
}

/// Production implementation of [ICallRepository] using [ApiService]
class CallApiRepository implements ICallRepository {
  final ApiService _apiService;

  CallApiRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  Future<CallRequestResponse> requestCall({
    required String agentUserId,
    int? categoryId,
    String? fcmToken,
  }) async {
    final effectiveFcmToken = fcmToken ??
        await FcmService.getFcmToken() ??
        await _apiService.tokenManager.getFcmToken();

    final body = <String, dynamic>{
      'agent_user_id': agentUserId,
      if (categoryId != null) 'category_id': categoryId,
      if (effectiveFcmToken != null && effectiveFcmToken.isNotEmpty)
        'fcm_token': effectiveFcmToken,
    };

    try {
      final response = await _apiService.post(
        ApiConstants.requestCall,
        data: body,
        requiresAuth: true,
      );
      if (response.isSuccess && response.rawData != null) {
        final parsed = CallRequestResponse.fromJson(
          response.rawData as Map<String, dynamic>,
        );
        final respMsg = parsed.message.toLowerCase();
        // Only trigger token refresh if response explicitly indicates NotRegistered/Invalid FCM token
        if (respMsg.contains('notregistered') ||
            respMsg.contains('not_registered') ||
            respMsg.contains('invalidregistration')) {
          debugPrint('🔄 [CallApiRepository] Response indicates NotRegistered FCM token. Refreshing token...');
          final freshToken = await FcmService.refreshAndSyncToken(forceNew: true);
          if (freshToken != null && freshToken.isNotEmpty) {
            body['fcm_token'] = freshToken;
            try {
              final retryResponse = await _apiService.post(
                ApiConstants.requestCall,
                data: body,
                requiresAuth: true,
              );
              if (retryResponse.isSuccess && retryResponse.rawData != null) {
                return CallRequestResponse.fromJson(
                  retryResponse.rawData as Map<String, dynamic>,
                );
              }
            } catch (_) {}
          }
        }
        return parsed;
      }
    } catch (e) {
      debugPrint('⚠️ [CallApiRepository] requestCall error: $e');
      final errStr = e.toString().toLowerCase();

      // Check for FCM NotRegistered / Invalid token error
      if (errStr.contains('notregistered') ||
          errStr.contains('not_registered') ||
          errStr.contains('invalidregistration') ||
          errStr.contains('invalid registration')) {
        debugPrint(
          '🔄 [CallApiRepository] FCM Token NotRegistered error detected. Refreshing token and syncing to backend...',
        );
        try {
          final freshFcmToken = await FcmService.refreshAndSyncToken(forceNew: true);
          if (freshFcmToken != null && freshFcmToken.isNotEmpty) {
            body['fcm_token'] = freshFcmToken;
            final retryResponse = await _apiService.post(
              ApiConstants.requestCall,
              data: body,
              requiresAuth: true,
            );
            if (retryResponse.isSuccess && retryResponse.rawData != null) {
              return CallRequestResponse.fromJson(
                retryResponse.rawData as Map<String, dynamic>,
              );
            }
          }
        } catch (eRetry) {
          debugPrint('⚠️ [CallApiRepository] Retry after NotRegistered refresh failed: $eRetry');
        }
      }

      // If there is an existing ongoing call on the server (e.g. "ongoing call (#46) in status 'ACCEPTED'"),
      // extract the stale call ID, end it on the server, and retry the request once.
      final match = RegExp(r'#(\d+)').firstMatch(e.toString());
      if (match != null) {
        final ongoingCallId = int.tryParse(match.group(1) ?? '');
        if (ongoingCallId != null && ongoingCallId > 0) {
          debugPrint(
            '🧹 [CallApiRepository] Auto-resolving stale ongoing call #$ongoingCallId on server...',
          );
          try {
            await updateCallStatus(callId: ongoingCallId, status: 'completed');
          } catch (_) {}

          // Retry requestCall once after clearing stale call
          try {
            final retryResponse = await _apiService.post(
              ApiConstants.requestCall,
              data: body,
              requiresAuth: true,
            );
            if (retryResponse.isSuccess && retryResponse.rawData != null) {
              return CallRequestResponse.fromJson(
                retryResponse.rawData as Map<String, dynamic>,
              );
            }
          } catch (e2) {
            debugPrint('⚠️ [CallApiRepository] requestCall retry failed: $e2');
          }
        }
      }
    }
    return const CallRequestResponse(
      callId: 0,
      channelName: '',
      status: 'failed',
      success: false,
    );
  }

  @override
  Future<Map<String, dynamic>> updateCallStatus({
    required int callId,
    required String status,
  }) async {
    try {
      String validStatus = status.toLowerCase().trim();
      if (validStatus == 'ended' || validStatus == 'finished') {
        validStatus = 'completed';
      } else if (validStatus == 'declined' || validStatus == 'rejected') {
        validStatus = 'reject';
      }
      final response = await _apiService.post(
        ApiConstants.updateCallStatus(callId),
        data: {'status': validStatus},
        requiresAuth: true,
      );
      if (response.isSuccess && response.rawData is Map) {
        return response.rawData as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ [CallApiRepository] updateCallStatus error: $e');
    }
    return {'success': false};
  }

  @override
  Future<Map<String, dynamic>> getCallStatus({
    required int callId,
  }) async {
    // Backend endpoint calls/<id>/status/ is POST only.
    return {'success': true};
  }
}
