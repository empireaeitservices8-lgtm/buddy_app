import 'package:agora_token_generator/agora_token_generator.dart';

/// Central Agora RTC Engine configuration and credential constants.
class AgoraConstants {
  AgoraConstants._();

  /// Agora App ID
  static const String appId = '747f7b36828c4bd0a7fb9a9128f3a32f';

  /// Agora Primary Certificate
  static const String appCertificate = 'ea6d70dc55f541ec81daa5a158c311dd';

  /// Default channel prefix
  static const String channelPrefix = 'gabby_call_';

  /// Helper to generate a unique Agora channel name between caller and agent
  static String generateChannelId({required String callerId, required String agentId}) {
    final sorted = [callerId.trim(), agentId.trim()]..sort();
    return '$channelPrefix${sorted[0]}_${sorted[1]}';
  }

  /// Generates a valid Agora RTC token for the given [channelName] and [uid]
  static String generateRtcToken({
    required String channelName,
    required int uid,
    int tokenExpireSeconds = 86400,
  }) {
    try {
      return RtcTokenBuilder.buildTokenWithUid(
        appId: appId,
        appCertificate: appCertificate,
        channelName: channelName,
        uid: uid,
        tokenExpireSeconds: tokenExpireSeconds,
      );
    } catch (_) {
      return '';
    }
  }
}
