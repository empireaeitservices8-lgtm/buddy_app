class ApiConstants {
  ApiConstants._();

  /// Base API URL for Buddy backend
  static const String baseUrl = 'https://buddy2026.pythonanywhere.com/api/';

  // Auth Endpoints
  static const String fcmToken = 'fcm-token/';
  static const String sendOtp = 'auth/caller/signup/send-otp/';
  static const String callerSignupSendOtp = 'auth/caller/signup/send-otp/';
  static const String callerLoginSendOtp = 'auth/caller/login/send-otp/';
  static const String verifyOtp = 'auth/caller/signup/verify-otp/';
  static const String callerSignupVerifyOtp = 'auth/caller/signup/verify-otp/';
  static const String callerLoginVerifyOtp = 'auth/caller/login/verify-otp/';
  static const String callerCompleteProfile = 'auth/caller/signup/complete-profile/';
  static const String agentLogin = 'auth/listener/login/';
  static const String listenerLogin = 'auth/listener/login/';
  static const String agentLogout = 'auth/listener/logout/';
  static const String listenerLogout = 'auth/listener/logout/';
  static const String logout = 'auth/logout/';

  // User Profile Endpoints
  static const String profile = 'caller/profile/';
  static const String callerProfile = 'caller/profile/';
  static const String updateProfile = 'caller/profile/';
  static const String updateInterests = 'users/interests/';

  // Matches & Professions & Interests & Categories
  static const String categories = 'conversation-categories/';
  static const String conversationCategories = 'conversation-categories/';
  static const String interests = 'interests/';
  static const String professions = 'conversation-categories/';
  static const String matches = 'matches/';
  static const String discoverAgents = 'agents/discover/';

  // Calls & Wallet Endpoints
  static const String callLogs = 'calls/history/';
  static const String startCall = 'calls/start/';
  static const String requestCall = 'calls/request/';
  static const String endCall = 'calls/end/';
  static String updateCallStatus(dynamic callId) => 'calls/$callId/status/';
  static String reviewCall(dynamic agentId) => 'calls/$agentId/review/';
  static String rateCall(dynamic callId) => 'calls/$callId/review/';
  static const String submitRating = 'agent/rating/';
  static const String coins = 'coins/';
  static const String walletBalance = 'coins/';
  static const String coinHistory = 'coins/history/';
  static const String addCoins = 'coins/add/';

  // Agent Endpoints
  static const String agentDashboard = 'agent/dashboard/';
  static const String agentProfile = 'agent/profile/';
  static const String agentRating = 'agent/rating/';
  static const String agentDutyOn = 'agent/duty/on/';
  static const String agentDutyOff = 'agent/duty/off/';
  static const String agentDutyToggle = 'agent/duty-toggle/';
  static const String agentDutyForm = 'agent/duty-form/';
  static const String agentEarnings = 'agent/earnings/';
  static const String requestPayout = 'agent/request-payout/';

  /// Helper to construct full URL for an endpoint
  static String fullUrl(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$cleanBase$cleanEndpoint';
  }
}
