import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_service.dart';
import '../models/caller_intent_model.dart';
import '../models/coin_transaction.dart';
import '../models/interest_model.dart';
import '../models/match_model.dart';
import '../models/user_profile.dart';
import 'user_repository.dart';

/// Production-grade implementation of [IUserRepository] using [ApiService].
class UserApiRepository implements IUserRepository {
  final ApiService _apiService;
  UserProfile? _cachedProfile;

  UserApiRepository({ApiService? apiService, UserProfile? initialProfile})
    : _apiService = apiService ?? ApiService(),
      _cachedProfile = initialProfile;

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiService.get<UserProfile>(
        ApiConstants.profile,
        requiresAuth: true,
        converter: (json) {
          if (json is Map<String, dynamic>) {
            return UserProfile.fromJson(json);
          }
          return _cachedProfile ?? const UserProfile();
        },
      );

      if (response.data != null) {
        _cachedProfile = response.data;
        return response.data!;
      }

      return _cachedProfile ?? const UserProfile();
    } on ApiException {
      if (_cachedProfile != null) return _cachedProfile!;
      rethrow;
    } catch (e) {
      if (_cachedProfile != null) return _cachedProfile!;
      throw UnexpectedException(message: 'Failed to fetch profile: $e');
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final payload = profile.toJson();
      try {
        final response = await _apiService.patch<UserProfile>(
          ApiConstants.callerProfile,
          data: payload,
          requiresAuth: true,
          converter: (json) {
            if (json is Map<String, dynamic>) {
              return UserProfile.fromJson(json);
            }
            return profile;
          },
        );

        if (response.data != null) {
          _cachedProfile = response.data;
          return response.data!;
        }
      } catch (_) {
        final response = await _apiService.put<UserProfile>(
          ApiConstants.callerProfile,
          data: payload,
          requiresAuth: true,
          converter: (json) {
            if (json is Map<String, dynamic>) {
              return UserProfile.fromJson(json);
            }
            return profile;
          },
        );

        if (response.data != null) {
          _cachedProfile = response.data;
          return response.data!;
        }
      }

      _cachedProfile = profile;
      return profile;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to update profile: $e');
    }
  }

  @override
  Future<List<InterestItem>> getAvailableInterests() async {
    try {
      final response = await _apiService.get<List<InterestItem>>(
        ApiConstants.interests,
        requiresAuth: false,
        converter: (json) {
          if (json is List) {
            return json
                .map((e) => InterestItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return defaultInterestsList;
        },
      );

      return response.data ?? defaultInterestsList;
    } catch (_) {
      return defaultInterestsList;
    }
  }

  @override
  Future<List<String>> updateInterests(List<String> interests) async {
    try {
      final response = await _apiService.post<List<String>>(
        ApiConstants.updateInterests,
        data: {'interests': interests},
        converter: (json) {
          if (json is List) {
            return json.map((e) => e.toString()).toList();
          }
          if (json is Map && json['interests'] is List) {
            return (json['interests'] as List)
                .map((e) => e.toString())
                .toList();
          }
          return interests;
        },
      );

      return response.data ?? interests;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to update interests: $e');
    }
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    return imageFile.path;
  }

  @override
  Future<List<CallLogItem>> getCallHistory() async {
    try {
      final response = await _apiService.get(
        ApiConstants.callLogs,
        requiresAuth: true,
      );

      if (response.rawData is Map) {
        final raw = response.rawData as Map<String, dynamic>;
        final list = (raw['data'] is List)
            ? raw['data'] as List
            : (raw['calls'] is List ? raw['calls'] as List : []);

        return list
            .map((e) => CallLogItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to fetch call history: $e');
    }
  }

  @override
  Future<int> getCoinsBalance() async {
    try {
      final response = await _apiService.get(
        ApiConstants.coins,
        requiresAuth: true,
      );

      if (response.rawData is Map) {
        final raw = response.rawData as Map<String, dynamic>;
        final dynamic rawCoins =
            raw['coins'] ??
            raw['balance'] ??
            (raw['data'] is Map
                ? ((raw['data'] as Map)['coins'] ??
                      (raw['data'] as Map)['balance'])
                : null);

        if (rawCoins is int) return rawCoins;
        if (rawCoins is num) return rawCoins.toInt();
        if (rawCoins != null) {
          return int.tryParse(rawCoins.toString()) ?? 0;
        }
      }
      return 0;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to fetch coins balance: $e');
    }
  }

  @override
  Future<CoinHistoryResponse> getCoinHistory() async {
    try {
      final response = await _apiService.get<CoinHistoryResponse>(
        ApiConstants.coinHistory,
        requiresAuth: true,
        converter: (json) {
          if (json is Map<String, dynamic>) {
            return CoinHistoryResponse.fromJson(json);
          }
          return const CoinHistoryResponse();
        },
      );

      return response.data ?? const CoinHistoryResponse();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to fetch coin history: $e');
    }
  }

  @override
  Future<int> addCoins(int amount) async {
    try {
      final response = await _apiService.post(
        ApiConstants.addCoins,
        data: {'coins': amount},
        requiresAuth: true,
      );

      if (response.rawData is Map) {
        final raw = response.rawData as Map<String, dynamic>;
        final dynamic rawCoins =
            raw['coins'] ??
            raw['balance'] ??
            (raw['data'] is Map
                ? ((raw['data'] as Map)['coins'] ??
                      (raw['data'] as Map)['balance'])
                : null);

        if (rawCoins is int) return rawCoins;
        if (rawCoins is num) return rawCoins.toInt();
        if (rawCoins != null) {
          return int.tryParse(rawCoins.toString()) ?? 0;
        }
      }
      return 0;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to add coins: $e');
    }
  }

  @override
  Future<List<CallerIntent>> getConversationCategories({
    List<String>? categoryIds,
    bool availableOnly = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['category_ids'] = categoryIds.join(',');
      }
      if (availableOnly) {
        queryParams['available_only'] = 'true';
      }

      final response = await _apiService.get(
        ApiConstants.conversationCategories,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        requiresAuth: true,
      );

      debugPrint('📂 [ConversationCategories Response]: status=${response.statusCode}, data=${response.rawData}');

      if (response.rawData is Map) {
        final raw = response.rawData as Map<String, dynamic>;
        final list = (raw['data'] is List)
            ? raw['data'] as List
            : (raw['results'] is List
                ? raw['results'] as List
                : (raw['categories'] is List ? raw['categories'] as List : []));

        if (list.isNotEmpty) {
          return list
              .map((e) => CallerIntent.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } else if (response.rawData is List) {
        final list = response.rawData as List;
        if (list.isNotEmpty) {
          return list
              .map((e) => CallerIntent.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
      return defaultCallerIntents;
    } on ApiException {
      return defaultCallerIntents;
    } catch (_) {
      return defaultCallerIntents;
    }
  }

  String? _lastDiscoverMessage;

  @override
  String? get lastDiscoverMessage => _lastDiscoverMessage;

  @override
  Future<List<MatchProfile>> discoverAgents({
    List<String>? conversationCategoryIds,
    String? professionId,
    bool availableOnly = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (conversationCategoryIds != null && conversationCategoryIds.isNotEmpty) {
        queryParams['conversation_categories'] = conversationCategoryIds.join(',');
      }
      if (professionId != null && professionId.trim().isNotEmpty) {
        queryParams['profession'] = professionId.trim();
      }
      if (availableOnly) {
        queryParams['available_only'] = 'true';
      }

      final response = await _apiService.get(
        ApiConstants.discoverAgents,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        requiresAuth: true,
      );

      try {
        final pretty = const JsonEncoder.withIndent('  ').convert(response.rawData);
        developer.log(pretty, name: 'DiscoverAgents');
        for (final line in pretty.split('\n')) {
          debugPrint('🔍 [DiscoverAgents Response]: $line');
        }
      } catch (_) {
        debugPrint(
          '🔍 [DiscoverAgents Response]: status=${response.statusCode}, data=${response.rawData}',
        );
      }

      if (response.rawData is Map) {
        final raw = response.rawData as Map<String, dynamic>;
        _lastDiscoverMessage = raw['message']?.toString();
        final list = (raw['data'] is List)
            ? raw['data'] as List
            : (raw['results'] is List ? raw['results'] as List : []);

        final agents = <MatchProfile>[];
        for (int i = 0; i < list.length; i++) {
          if (list[i] is Map) {
            agents.add(
              MatchProfile.fromJson(list[i] as Map<String, dynamic>, i),
            );
          }
        }
        return agents;
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to discover agents: $e');
    }
  }
}
