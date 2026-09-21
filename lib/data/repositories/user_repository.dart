import 'dart:io';
import '../models/caller_intent_model.dart';
import '../models/coin_transaction.dart';
import '../models/interest_model.dart';
import '../models/match_model.dart';
import '../models/user_profile.dart';

/// Contract definition for User data operations.
abstract class IUserRepository {
  /// Fetches the authenticated user profile from backend.
  Future<UserProfile> getProfile();

  /// Updates profile details (name, gender, age, bio, etc.).
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Fetches the list of all available interest tags from backend.
  Future<List<InterestItem>> getAvailableInterests();

  /// Updates user interests list.
  Future<List<String>> updateInterests(List<String> interests);

  /// Uploads user avatar image file via multipart form data.
  Future<String> uploadAvatar(File imageFile);

  /// Fetches call logs and history from the backend.
  Future<List<CallLogItem>> getCallHistory();

  /// Fetches the authenticated user's coin balance from the backend.
  Future<int> getCoinsBalance();

  /// Fetches full coin purchase & transaction history.
  Future<CoinHistoryResponse> getCoinHistory();

  /// Adds coins to user's wallet via backend POST api.
  Future<int> addCoins(int amount);

  /// Fetches conversation categories from backend:
  /// GET /api/conversation-categories/?category_ids=1,2,3&available_only=true
  Future<List<CallerIntent>> getConversationCategories({
    List<String>? categoryIds,
    bool availableOnly = true,
  });

  /// Discovers agents from backend matching conversation categories, profession, and availability.
  /// GET /api/agents/discover/?conversation_categories=1,2,3&profession=1&available_only=true
  Future<List<MatchProfile>> discoverAgents({
    List<String>? conversationCategoryIds,
    String? professionId,
    bool availableOnly = true,
  });

  /// Last response message returned from discover agents API.
  String? get lastDiscoverMessage;
}
