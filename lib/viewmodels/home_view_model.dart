import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/agora_constants.dart';
import '../core/network/token_manager.dart';
import '../core/services/agora_service.dart';
import '../core/services/fcm_service.dart';
import '../core/services/sound_service.dart';
import '../data/models/caller_intent_model.dart';
import '../data/models/call_request_model.dart';
import '../data/models/coin_transaction.dart';
import '../data/models/match_model.dart';
import '../data/models/user_profile.dart';
import '../data/models/user_role.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/call_repository.dart';
import '../data/repositories/user_repository.dart';
import 'base_view_model.dart';

enum HomeExploreStep { intentSelection, categoryMatches }

class HomeViewModel extends BaseViewModel {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;
  final ICallRepository _callRepository;
  final AgoraService _agoraService;

  UserProfile? _userProfile;
  UserRole _role = UserRole.user;
  int _activeTab =
      0; // 0: Explore/Categories, 1: Coins/Wallet, 2: Calls/Phone, 3: Profile/Person
  HomeExploreStep _exploreStep = HomeExploreStep.intentSelection;
  bool _isLoggedOut = false;
  bool get isLoggedOut => _isLoggedOut;

  // Wallet & Coin History
  int _walletCoins = 0;
  bool _isLoadingWallet = false;
  bool _isLoadingCoinHistory = false;
  CoinHistoryResponse? _coinHistory;

  // Search & Filter
  String _searchQuery = '';
  String? _selectedCategory;
  final Set<String> _favoriteMatchIds = {};
  final Map<String, MatchProfile> _allKnownMatches = {};
  final Map<String, MatchProfile> _favoriteMatchesCache = {};
  bool _showFavoritesOnly = false;

  // Live Call State
  MatchProfile? _activeCallMatch;
  bool _isCallAttended = false;
  bool _wasLastCallConnected = false;
  bool _hasTriggeredLowCoinWarning = false;
  int _callDurationSeconds = 0;
  int _callCoinsSpent = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  Timer? _callTimer;
  Timer? _callStatusPollTimer;
  StreamSubscription<int?>? _remoteUserSub;
  StreamSubscription<String>? _fcmTokenSubscription;

  // Caller Intent Multi-Selection (What do you need right now?)
  // Caller Intent Multi-Selection (What do you need right now?)
  final Set<String> _selectedIntentIds = {};
  List<CallerIntent> _dynamicCallerIntents = [];
  Set<String> get selectedIntentIds => _selectedIntentIds;
  List<CallerIntent> get callerIntents => _dynamicCallerIntents.isNotEmpty
      ? _dynamicCallerIntents
      : defaultCallerIntents;
  List<CallerIntent> get selectedIntents => callerIntents
      .where((i) => isIntentSelected(i))
      .toList();
  CallerIntent? get selectedIntent =>
      selectedIntents.isNotEmpty ? selectedIntents.first : null;
  HomeExploreStep get exploreStep => _exploreStep;

  // Listener Categories & Matches
  static const List<ProfessionCategory> _defaultProfessions = [
    ProfessionCategory(
      id: '1',
      title: 'Teacher',
      subTitle: 'Educator, School/College Teacher, Professor, Tutor',
      matchCount: 0,
      emoji: '📚',
      bgColor: Color(0xFFFFB7D5),
    ),
    ProfessionCategory(
      id: 'doctor',
      title: 'Doctor',
      subTitle: 'Medical professional, Healthcare & Wellness advice',
      matchCount: 0,
      emoji: '🩺',
      bgColor: Color(0xFFD6F887),
    ),
    ProfessionCategory(
      id: 'engineer',
      title: 'Engineer',
      subTitle: 'Software, Tech, Engineering & Coding mentors',
      matchCount: 0,
      emoji: '💻',
      bgColor: Color(0xFFB8C4FE),
    ),
    ProfessionCategory(
      id: 'student_companion',
      title: 'Student Companion',
      subTitle: 'Talk about studies, college and life guidance',
      matchCount: 0,
      emoji: '🎓',
      bgColor: Color(0xFFE8D7FF),
    ),
    ProfessionCategory(
      id: 'career_guide',
      title: 'Career Guide',
      subTitle: 'Talk to someone experienced in your field',
      matchCount: 0,
      emoji: '💼',
      bgColor: Color(0xFFFFF7CE),
    ),
    ProfessionCategory(
      id: 'counselor',
      title: 'Counselor',
      subTitle: 'Perspective, emotional support & active listener',
      matchCount: 0,
      emoji: '🧠',
      bgColor: Color(0xFFFFE5D9),
    ),
    ProfessionCategory(
      id: 'travel_companion',
      title: 'Travel Companion',
      subTitle: 'Talk to someone who knows local places & cultures',
      matchCount: 0,
      emoji: '🌍',
      bgColor: Color(0xFFD0E8FF),
    ),
    ProfessionCategory(
      id: 'elder_companion',
      title: 'Elder Companion',
      subTitle: 'Someone to talk to regularly with warm care',
      matchCount: 0,
      emoji: '👴',
      bgColor: Color(0xFFFFF1DB),
    ),
    ProfessionCategory(
      id: 'language_partner',
      title: 'Language Partner',
      subTitle: 'Practice English / Hindi / Malayalam / etc.',
      matchCount: 0,
      emoji: '🗣️',
      bgColor: Color(0xFFD8F3DC),
    ),
  ];

  List<ProfessionCategory> _professions = List.from(_defaultProfessions);
  List<MatchProfile> _matches = [];

  List<CallLogItem> _callLogs = [];
  bool _isLoadingCallHistory = false;
  bool _isLoadingCategories = false;
  CallRequestResponse? _lastCallRequest;

  bool _isInitializing = false;
  bool _isInitialized = false;
  DateTime? _lastCoinsFetchTime;
  DateTime? _lastHistoryFetchTime;
  DateTime? _lastCallHistoryFetchTime;
  DateTime? _lastProfileFetchTime;
  DateTime? _lastCategoriesFetchTime;

  HomeViewModel({
    required IAuthRepository authRepository,
    required IUserRepository userRepository,
    ICallRepository? callRepository,
    AgoraService? agoraService,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _callRepository = callRepository ?? CallApiRepository(),
       _agoraService = agoraService ?? AgoraService() {
    _role = _authRepository.currentRole ?? UserRole.user;
    _userProfile = _authRepository.currentUser;
    init();
  }

  // Getters
  List<CallLogItem> get callLogs => _callLogs;
  bool get isLoadingCallHistory => _isLoadingCallHistory;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get discoverMessage => _userRepository.lastDiscoverMessage;
  int? _lastEndedCallId;
  int? get lastEndedCallId => _lastEndedCallId;
  CallRequestResponse? get lastCallRequest => _lastCallRequest;
  UserProfile? get userProfile => _userProfile;
  UserRole get role => _role;
  int get activeTab => _activeTab;
  int get walletCoins => _walletCoins;
  CoinHistoryResponse? get coinHistory => _coinHistory;
  List<CoinTransaction> get coinTransactions =>
      _coinHistory?.transactions ?? [];
  bool get isLoadingCoinHistory => _isLoadingCoinHistory;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedCategoryTitle {
    if (_selectedCategory != null && _selectedCategory!.trim().isNotEmpty) {
      final sel = _selectedCategory!.trim();
      final cat = _professions.cast<ProfessionCategory?>().firstWhere(
        (p) =>
            p != null &&
            (p.id.toString().toLowerCase() == sel.toLowerCase() ||
                p.title.toLowerCase() == sel.toLowerCase()),
        orElse: () => null,
      );
      if (cat != null && cat.title.trim().isNotEmpty) {
        return cat.title.trim();
      }
      // If it's a numeric ID that couldn't be resolved, return null rather than displaying a raw number
      if (int.tryParse(sel) != null) {
        return null;
      }
      return sel;
    }
    if (selectedIntent != null) {
      return selectedIntent!.title;
    }
    if (_selectedIntentIds.isNotEmpty) {
      final firstId = _selectedIntentIds.first;
      final intent = callerIntents.cast<CallerIntent?>().firstWhere(
        (i) =>
            i != null &&
            (i.id == firstId ||
                i.id.toLowerCase() == firstId.toLowerCase() ||
                i.title.toLowerCase() == firstId.toLowerCase()),
        orElse: () => null,
      );
      return intent?.title ?? firstId;
    }
    return null;
  }

  MatchProfile? get activeCallMatch => _activeCallMatch;
  bool get isCallAttended => _isCallAttended;
  bool get wasLastCallConnected => _wasLastCallConnected;
  bool get isLowCoinWarning => _isCallAttended && _walletCoins <= 300;
  int get callDurationSeconds => _callDurationSeconds;
  int get callCoinsSpent => _callCoinsSpent;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isCallActive => _activeCallMatch != null;
  AgoraService get agoraService => _agoraService;

  bool get showFavoritesOnly => _showFavoritesOnly;
  int get favoritesCount => _favoriteMatchIds.length;
  int get allMatchesCount => _matches.length;
  List<MatchProfile> get matches => _matches;

  bool isFavorite(String id) => _favoriteMatchIds.contains(id);

  int getMatchCountForCategory(ProfessionCategory item) {
    if (item.matches.isNotEmpty) {
      return item.matches.length;
    }
    final itemId = item.id.toLowerCase();
    final itemTitle = item.title.toLowerCase();
    return _matches.where((m) {
      final pCat = m.professionCategory.toLowerCase();
      final prof = m.profession.toLowerCase();
      final pId = (m.professionId ?? '').toLowerCase();
      if (pCat == itemTitle ||
          prof == itemTitle ||
          (pId.isNotEmpty && pId == itemId)) {
        return true;
      }
      return m.matchesCategory(item.id, item.title);
    }).length;
  }

  Future<void> _loadFavoritesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('user_favorite_ids');
      if (savedIds != null && savedIds.isNotEmpty) {
        _favoriteMatchIds.addAll(savedIds);
      }
      final savedProfilesJson = prefs.getStringList('user_favorite_profiles');
      if (savedProfilesJson != null) {
        for (final itemStr in savedProfilesJson) {
          try {
            final map = jsonDecode(itemStr) as Map<String, dynamic>;
            final profile = MatchProfile.fromJson(map);
            _allKnownMatches[profile.id] = profile;
            _favoriteMatchesCache[profile.id] = profile;
          } catch (_) {}
        }
      }
      final savedCoins = prefs.getInt('last_known_wallet_coins');
      if (savedCoins != null) {
        _walletCoins = savedCoins;
      }
      notifyListenersSafely();
    } catch (_) {}
  }

  Future<void> _saveCachedCoins(int coins) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_known_wallet_coins', coins);
    } catch (_) {}
  }

  Future<void> _saveFavoritesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'user_favorite_ids',
        _favoriteMatchIds.toList(),
      );
      final profilesToSave = _favoriteMatchIds
          .map((id) => _favoriteMatchesCache[id] ?? _allKnownMatches[id])
          .whereType<MatchProfile>()
          .map((p) => jsonEncode(p.toJson()))
          .toList();
      await prefs.setStringList('user_favorite_profiles', profilesToSave);
    } catch (_) {}
  }

  MatchProfile? _findMatchById(String id) {
    if (_favoriteMatchesCache.containsKey(id)) {
      return _favoriteMatchesCache[id];
    }
    if (_allKnownMatches.containsKey(id)) {
      return _allKnownMatches[id];
    }
    for (final m in _matches) {
      if (m.id == id) return m;
    }
    for (final cat in _professions) {
      for (final m in cat.matches) {
        if (m.id == id) return m;
      }
    }
    return null;
  }

  void toggleFavorite(String id, [MatchProfile? profile]) {
    if (profile != null) {
      _allKnownMatches[id] = profile;
    }

    if (_favoriteMatchIds.contains(id)) {
      _favoriteMatchIds.remove(id);
      _favoriteMatchesCache.remove(id);
    } else {
      _favoriteMatchIds.add(id);
      final match = profile ?? _allKnownMatches[id] ?? _findMatchById(id);
      if (match != null) {
        _allKnownMatches[id] = match;
        _favoriteMatchesCache[id] = match;
      }
    }
    _saveFavoritesToStorage();
    notifyListenersSafely();
  }

  void toggleShowFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListenersSafely();
  }

  String get formattedCallDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  List<ProfessionCategory> get filteredProfessions {
    // Only include categories that have at least 1 match
    var list = _professions
        .where((p) => getMatchCountForCategory(p) > 0)
        .toList();

    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.subTitle.toLowerCase().contains(q);
    }).toList();
  }

  List<MatchProfile> get filteredMatches {
    if (_showFavoritesOnly) {
      // Collect all favorites from cache and known matches so no favorite is ever missing
      final allFavsMap = <String, MatchProfile>{};
      for (final e in _favoriteMatchesCache.entries) {
        if (_favoriteMatchIds.contains(e.key)) {
          allFavsMap[e.key] = e.value;
        }
      }
      for (final e in _allKnownMatches.entries) {
        if (_favoriteMatchIds.contains(e.key)) {
          allFavsMap[e.key] = e.value;
        }
      }
      for (final m in _matches) {
        if (_favoriteMatchIds.contains(m.id)) {
          allFavsMap[m.id] = m;
        }
      }

      List<MatchProfile> favList = allFavsMap.values.toList();

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        favList = favList
            .where(
              (m) =>
                  m.name.toLowerCase().contains(q) ||
                  m.profession.toLowerCase().contains(q) ||
                  m.professionCategory.toLowerCase().contains(q) ||
                  m.bio.toLowerCase().contains(q) ||
                  m.interests.any((i) => i.toLowerCase().contains(q)),
            )
            .toList();
      }

      return favList;
    }

    List<MatchProfile> list = _matches;

    // 1. If a specific category is selected, ALWAYS show matches for this category
    if (_selectedCategory != null && _selectedCategory!.trim().isNotEmpty) {
      final sel = _selectedCategory!.trim().toLowerCase();
      final cat = _professions.cast<ProfessionCategory?>().firstWhere(
        (p) =>
            p != null &&
            (p.id.toString().toLowerCase() == sel ||
                p.title.toLowerCase() == sel),
        orElse: () => null,
      );

      final catMatches = cat?.matches ?? [];
      if (catMatches.isNotEmpty) {
        list = catMatches;
      } else {
        final catId = cat?.id ?? sel;
        final catTitle = cat?.title ?? sel;
        list = list.where((m) => m.matchesCategory(catId, catTitle)).toList();
      }
    }
    // 2. Otherwise, if multiple intents are selected, filter across those intents
    else if (_selectedIntentIds.isNotEmpty) {
      list = list.where((m) {
        return _selectedIntentIds.any((intentId) {
          final intent = callerIntents.cast<CallerIntent?>().firstWhere(
            (i) =>
                i != null &&
                (i.id == intentId ||
                    i.title.toLowerCase() == intentId.toLowerCase()),
            orElse: () => null,
          );
          return m.matchesCategory(
            intentId,
            intent?.targetCategory ?? intent?.title,
          );
        });
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list
          .where(
            (m) =>
                m.name.toLowerCase().contains(q) ||
                m.profession.toLowerCase().contains(q) ||
                m.professionCategory.toLowerCase().contains(q) ||
                m.bio.toLowerCase().contains(q) ||
                m.interests.any((i) => i.toLowerCase().contains(q)),
          )
          .toList();
    }

    return list;
  }

  // Tab navigation (0: Categories/Explore, 1: Coins/Wallet, 2: Calls History, 3: Profile)
  void setTab(int index) {
    if (index == 0) {
      _selectedCategory = null;
      _exploreStep = HomeExploreStep.intentSelection;
    }
    _activeTab = index;
    if (index == 1) {
      fetchCoinsBalance(silent: true, force: true);
      fetchCoinHistory(silent: true, force: true);
    } else if (index == 2) {
      fetchCallHistory(silent: true, force: true);
    } else if (index == 3) {
      fetchUserProfile(silent: true, force: true);
      fetchCoinsBalance(silent: true, force: true);
    }
    notifyListenersSafely();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListenersSafely();
  }

  void setExploreStep(HomeExploreStep step) {
    _exploreStep = step;
    notifyListenersSafely();
  }

  bool isIntentSelected(dynamic intentOrId) {
    if (intentOrId is CallerIntent) {
      return _selectedIntentIds.contains(intentOrId.id) ||
          _selectedIntentIds.contains(intentOrId.id.toLowerCase()) ||
          _selectedIntentIds.contains(intentOrId.title) ||
          _selectedIntentIds.contains(intentOrId.title.toLowerCase()) ||
          _selectedIntentIds.contains(intentOrId.targetCategory) ||
          _selectedIntentIds.contains(intentOrId.targetCategory.toLowerCase());
    } else if (intentOrId is String) {
      if (_selectedIntentIds.contains(intentOrId) ||
          _selectedIntentIds.contains(intentOrId.toLowerCase())) {
        return true;
      }
      for (final intent in callerIntents) {
        if (intent.id == intentOrId ||
            intent.id.toLowerCase() == intentOrId.toLowerCase() ||
            intent.title.toLowerCase() == intentOrId.toLowerCase()) {
          return _selectedIntentIds.contains(intent.id) ||
              _selectedIntentIds.contains(intent.id.toLowerCase()) ||
              _selectedIntentIds.contains(intent.title) ||
              _selectedIntentIds.contains(intent.title.toLowerCase());
        }
      }
    }
    return false;
  }

  void toggleIntentSelection(CallerIntent intent) {
    if (isIntentSelected(intent)) {
      _selectedIntentIds.remove(intent.id);
      _selectedIntentIds.remove(intent.id.toLowerCase());
      _selectedIntentIds.remove(intent.title);
      _selectedIntentIds.remove(intent.title.toLowerCase());
      _selectedIntentIds.remove(intent.targetCategory);
      _selectedIntentIds.remove(intent.targetCategory.toLowerCase());
    } else {
      _selectedIntentIds.add(intent.id);
    }
    notifyListenersSafely();
  }

  void selectAllIntents() {
    _selectedIntentIds.clear();
    _selectedIntentIds.addAll(defaultCallerIntents.map((e) => e.id));
    notifyListenersSafely();
  }

  void clearIntentSelections() {
    _selectedIntentIds.clear();
    notifyListenersSafely();
  }

  void setMultipleSelectedIntents(Set<String> ids) {
    _selectedIntentIds.clear();
    _selectedIntentIds.addAll(ids);
    notifyListenersSafely();
  }

  void submitSelectedIntents() {
    if (_selectedIntentIds.isEmpty) return;
    _selectedCategory = null;
    _isLoadingCategories = true;
    _matches = [];
    _professions = [];
    _exploreStep = HomeExploreStep.categoryMatches;
    notifyListenersSafely();
    fetchCategories(silent: false, force: true);
  }

  void removeSelectedIntent(String id) {
    _selectedIntentIds.remove(id);
    if (_selectedIntentIds.isEmpty) {
      _exploreStep = HomeExploreStep.intentSelection;
    }
    notifyListenersSafely();
    if (_selectedIntentIds.isNotEmpty && _exploreStep == HomeExploreStep.categoryMatches) {
      fetchCategories(silent: false, force: true);
    }
  }

  void selectIntentAndGoToCategories(CallerIntent intent) {
    _selectedIntentIds.clear();
    _selectedIntentIds.add(intent.id);
    _selectedCategory = null;
    _isLoadingCategories = true;
    _matches = [];
    _professions = [];
    _exploreStep = HomeExploreStep.categoryMatches;
    notifyListenersSafely();
    fetchCategories(silent: false, force: true);
  }

  void goToCategoriesStep() {
    _exploreStep = HomeExploreStep.categoryMatches;
    _isLoadingCategories = true;
    notifyListenersSafely();
    fetchCategories(silent: false, force: true);
  }

  void selectCategoryInExplore(String categoryIdOrTitle) {
    final cat = _professions.cast<ProfessionCategory?>().firstWhere(
      (p) =>
          p != null &&
          (p.id.toString().toLowerCase() == categoryIdOrTitle.toLowerCase() ||
              p.title.toLowerCase() == categoryIdOrTitle.toLowerCase()),
      orElse: () => null,
    );
    _selectedCategory = cat?.title.isNotEmpty == true
        ? cat!.title
        : categoryIdOrTitle;
    _isLoadingCategoryMatches = true;
    _exploreStep = HomeExploreStep.categoryMatches;
    notifyListenersSafely();
    fetchCategoryDetails(
      cat?.title.isNotEmpty == true ? cat!.title : categoryIdOrTitle,
      professionId: cat?.id.isNotEmpty == true ? cat!.id : categoryIdOrTitle,
      forceRefresh: true,
    );
  }

  void goBackInExplore() {
    _selectedCategory = null;
    _exploreStep = HomeExploreStep.intentSelection;
    notifyListenersSafely();
  }

  void selectCategoryAndGoToMatches(String categoryIdOrTitle) {
    final cat = _professions.cast<ProfessionCategory?>().firstWhere(
      (p) =>
          p != null &&
          (p.id.toString().toLowerCase() == categoryIdOrTitle.toLowerCase() ||
              p.title.toLowerCase() == categoryIdOrTitle.toLowerCase()),
      orElse: () => null,
    );
    _selectedCategory = cat?.title.isNotEmpty == true
        ? cat!.title
        : categoryIdOrTitle;
    _exploreStep = HomeExploreStep.categoryMatches;
    _activeTab = 0;
    if (cat != null && cat.matches.isNotEmpty) {
      for (final m in cat.matches) {
        _allKnownMatches[m.id] = m;
      }
    }
    notifyListenersSafely();
    fetchCategoryDetails(
      cat?.title.isNotEmpty == true ? cat!.title : categoryIdOrTitle,
      professionId: cat?.id.isNotEmpty == true ? cat!.id : categoryIdOrTitle,
    );
  }

  bool _isLoadingCategoryMatches = false;
  bool get isLoadingCategoryMatches => _isLoadingCategoryMatches;

  Future<void> fetchCategoryDetails(
    String categoryIdOrName, {
    String? professionId,
    bool forceRefresh = false,
  }) async {
    final cat = _professions.firstWhere(
      (p) =>
          p.id == categoryIdOrName ||
          p.title.toLowerCase() == categoryIdOrName.toLowerCase(),
      orElse: () => ProfessionCategory(
        id: professionId ?? categoryIdOrName,
        title: categoryIdOrName,
        subTitle: '',
        matchCount: 0,
        emoji: '🎧',
        bgColor: const Color(0xFFB8C4FE),
      ),
    );

    final bool hasExisting = cat.matches.isNotEmpty ||
        _matches.any((m) => m.matchesCategory(cat.id, cat.title));

    // Always show circular progress indicator while fetching API data
    _isLoadingCategoryMatches = true;
    notifyListenersSafely();

    try {
      // conversation_categories: selected conversation category IDs (e.g. 1,2,3)
      final convCatIds = _selectedIntentIds.isNotEmpty
          ? _selectedIntentIds.toList()
          : null;

      // profession: the ID of the selected profession category (e.g. 1, 9, 10)
      final effectiveProfessionId = professionId ??
          (int.tryParse(cat.id) != null ? cat.id : null);

      // Discover agents: GET /api/agents/discover/?conversation_categories=1,2,3&profession=1&available_only=true
      try {
        final catAgents = await _userRepository.discoverAgents(
          conversationCategoryIds: convCatIds,
          professionId: effectiveProfessionId,
          availableOnly: true,
        );

        final catIndex = _professions.indexWhere(
          (p) =>
              p.id == cat.id ||
              p.title.toLowerCase() == cat.title.toLowerCase(),
        );
        if (catIndex != -1) {
          _professions[catIndex] = _professions[catIndex].copyWith(
            matches: catAgents,
            matchCount: catAgents.length,
          );
        }

        if (catAgents.isNotEmpty) {
          for (final m in catAgents) {
            _allKnownMatches[m.id] = m;
          }
          final otherMatches = _matches
              .where(
                (m) =>
                    !catAgents.any((a) => a.id == m.id) &&
                    !m.matchesCategory(cat.id, cat.title),
              )
              .toList();
          _matches = [...otherMatches, ...catAgents];
        } else if (!hasExisting) {
          _matches = _matches
              .where((m) => !m.matchesCategory(cat.id, cat.title))
              .toList();
        }
      } catch (_) {}
    } catch (_) {
      // Keep existing matches on error
    } finally {
      _isLoadingCategoryMatches = false;
      notifyListenersSafely();
    }
  }

  void selectIntent(CallerIntent intent) {
    _selectedIntentIds.clear();
    _selectedIntentIds.add(intent.id);
    selectCategoryInExplore(intent.targetCategory);
  }

  void clearCategoryFilter() {
    _selectedCategory = null;
    _selectedIntentIds.clear();
    _showFavoritesOnly = false;
    notifyListenersSafely();
  }

  Future<void> fetchCategories({bool silent = false, bool force = false}) async {
    if (!force &&
        _lastCategoriesFetchTime != null &&
        DateTime.now().difference(_lastCategoriesFetchTime!) <
            const Duration(seconds: 30)) {
      return;
    }
    _lastCategoriesFetchTime = DateTime.now();

    if (!silent || force) {
      _isLoadingCategories = true;
      notifyListenersSafely();
    }
    try {
      // 1. Fetch conversation categories: GET /api/conversation-categories/?category_ids=1,2,3&available_only=true
      try {
        final targetCategoryIds = _selectedIntentIds.isNotEmpty
            ? _selectedIntentIds.toList()
            : null;
        final dynamicCats = await _userRepository.getConversationCategories(
          categoryIds: targetCategoryIds,
          availableOnly: true,
        );
        if (dynamicCats.isNotEmpty) {
          if (targetCategoryIds == null || targetCategoryIds.isEmpty) {
            _dynamicCallerIntents = dynamicCats;
          }
        }
      } catch (_) {}

      // 2. Discover available agents: GET /api/agents/discover/?conversation_categories=1,2,3&available_only=true
      try {
        final targetCategoryIds = _selectedIntentIds.isNotEmpty
            ? _selectedIntentIds.toList()
            : null;
        final discovered = await _userRepository.discoverAgents(
          conversationCategoryIds: targetCategoryIds,
          availableOnly: true,
        );
        if (discovered.isNotEmpty) {
          for (final m in discovered) {
            _allKnownMatches[m.id] = m;
          }
          _matches = discovered;
        } else if (targetCategoryIds != null) {
          _matches = [];
        } else {
          _matches = discovered;
        }
      } catch (_) {}

      // Sync listener categories (professions) from discovered matches
      _syncProfessionsWithMatches();
    } catch (_) {
      // Keep existing categories on failure
    } finally {
      _isLoadingCategories = false;
      notifyListenersSafely();
    }
  }

  void _syncProfessionsWithMatches() {
    final Map<String, ProfessionCategory> categoryMap = {};

    // 1. Add all categories derived from discovered matches
    for (final m in _matches) {
      final catName =
          (m.professionCategory.isNotEmpty
                  ? m.professionCategory
                  : m.profession)
              .trim();
      final catId = (m.professionId != null && m.professionId!.isNotEmpty)
          ? m.professionId!
          : catName.toLowerCase().replaceAll(' ', '_');

      if (catName.isNotEmpty) {
        final key = catName.toLowerCase();
        if (!categoryMap.containsKey(key)) {
          final existing = _professions.cast<ProfessionCategory?>().firstWhere(
            (p) =>
                p != null &&
                (p.id.toLowerCase() == catId.toLowerCase() ||
                    p.title.toLowerCase() == key),
            orElse: () => null,
          );

          final matchingForCat = _matches.where((match) {
            final pCat = match.professionCategory.toLowerCase();
            final prof = match.profession.toLowerCase();
            final pId = (match.professionId ?? '').toLowerCase();
            return pCat == key ||
                prof == key ||
                (pId.isNotEmpty && pId == catId.toLowerCase()) ||
                match.matchesCategory(catId, catName);
          }).toList();

          categoryMap[key] = ProfessionCategory(
            id: catId,
            title: catName,
            subTitle:
                m.categoryDescription ??
                (existing != null && existing.subTitle.isNotEmpty
                    ? existing.subTitle
                    : 'Connect and talk with verified ${catName.toLowerCase()}s'),
            matchCount: matchingForCat.length,
            emoji: existing?.emoji ?? _getEmojiForCategory(catName),
            bgColor:
                existing?.bgColor ?? _getBgColorForIndex(categoryMap.length),
            matches: matchingForCat,
          );
        }
      }
    }

    // 2. Only add predefined categories when no specific intent filter is active
    if (_selectedIntentIds.isEmpty) {
      for (final p in _defaultProfessions) {
        final key = p.title.toLowerCase();
        if (!categoryMap.containsKey(key)) {
          categoryMap[key] = p;
        }
      }
    }

    _professions = categoryMap.values.toList();
  }

  static Color _getBgColorForIndex(int index) {
    const bgColors = [
      Color(0xFFFFB7D5), // Pink
      Color(0xFFFFF7CE), // Pale Yellow
      Color(0xFFB8C4FE), // Lavender
      Color(0xFFD6F887), // Lime
      Color(0xFFD0E8FF), // Sky blue
      Color(0xFFFFE5D9), // Peach
      Color(0xFFE8D7FF), // Purple
      Color(0xFFD8F3DC), // Mint
      Color(0xFFFFF1DB), // Cream
    ];
    return bgColors[index % bgColors.length];
  }

  static String _getEmojiForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('nurse') || n.contains('caregiver') || n.contains('hospital')) {
      return '🩺';
    }
    if (n.contains('teacher') ||
        n.contains('educat') ||
        n.contains('tutor') ||
        n.contains('profess')) {
      return '📚';
    }
    if (n.contains('doctor') || n.contains('medic') || n.contains('health')) {
      return '🩺';
    }
    if (n.contains('engineer') ||
        n.contains('software') ||
        n.contains('tech') ||
        n.contains('code') ||
        n.contains('dev') ||
        n.contains('program')) {
      return '💻';
    }
    if (n.contains('student') || n.contains('college') || n.contains('studies')) {
      return '🎓';
    }
    if (n.contains('career') || n.contains('business') || n.contains('job')) {
      return '💼';
    }
    if (n.contains('counsel') || n.contains('psych') || n.contains('advice')) {
      return '🧠';
    }
    if (n.contains('travel') || n.contains('place') || n.contains('trip')) {
      return '🌍';
    }
    if (n.contains('elder') || n.contains('senior')) return '👴';
    if (n.contains('language') ||
        n.contains('english') ||
        n.contains('practice')) {
      return '🗣️';
    }
    if (n.contains('art') || n.contains('design') || n.contains('music')) {
      return '🎨';
    }
    if (n.contains('law') || n.contains('legal')) return '⚖️';
    return '🌟';
  }

  Future<void> fetchCallHistory({bool silent = false, bool force = false}) async {
    if (!force &&
        _lastCallHistoryFetchTime != null &&
        DateTime.now().difference(_lastCallHistoryFetchTime!) <
            const Duration(seconds: 30)) {
      return;
    }
    _lastCallHistoryFetchTime = DateTime.now();

    final bool showLoader = !silent && _callLogs.isEmpty;
    if (showLoader) {
      _isLoadingCallHistory = true;
      notifyListenersSafely();
    }
    try {
      final history = await _userRepository.getCallHistory();
      _callLogs = history;
    } catch (_) {
      // Keep existing list on failure
    } finally {
      _isLoadingCallHistory = false;
      notifyListenersSafely();
    }
  }

  // Live Call Controls with Agora RTC & Backend Call Request
  Future<void> startCall(MatchProfile match, {bool isVideo = false}) async {
    _activeCallMatch = match;
    _isCallAttended = false;
    _wasLastCallConnected = false;
    _hasTriggeredLowCoinWarning = false;
    _callDurationSeconds = 0;
    _callCoinsSpent = 0;
    _isMuted = false;
    _isSpeakerOn = true;
    _lastCallRequest = null;
    _callTimer?.cancel();
    _callTimer = null;
    _remoteUserSub?.cancel();
    clearError();
    notifyListenersSafely();

    // Listen for the remote agent to attend/join the channel
    _remoteUserSub = _agoraService.remoteUserJoinedStream.listen((remoteUid) {
      if (remoteUid != null) {
        debugPrint('📞 [HomeVM] Agent attended call (remoteUid: $remoteUid)');
        _onAgentAttendedCall();
      } else if (remoteUid == null && _isCallAttended) {
        debugPrint('📞 [HomeVM] Agent left call');
        endCall();
      }
    });

    try {
      // 1. Call Backend API: api/calls/request/ with agent_user_id
      final callResponse = await _callRepository.requestCall(
        agentUserId: match.id,
      );
      _lastCallRequest = callResponse;
      notifyListenersSafely();

      // 2. Determine Channel Name, Agora Token, and UID from API response
      final channelId = callResponse.channelName.isNotEmpty
          ? callResponse.channelName
          : (callResponse.callId > 0
              ? 'gabby_call_${callResponse.callId}'
              : AgoraConstants.generateChannelId(
                  callerId: _userProfile?.id ?? 'caller',
                  agentId: match.id,
                ));
      String? token = callResponse.agoraToken;
      int uid = 0;
      if (callResponse.uid != null && callResponse.uid! > 0) {
        uid = callResponse.uid!;
      } else if (_userProfile?.userId != null) {
        uid = int.tryParse(_userProfile!.userId!) ?? 0;
      } else if (_userProfile?.id != null) {
        uid = int.tryParse(_userProfile!.id!) ?? 0;
      }
      if (uid <= 0 && channelId.isNotEmpty) {
        final parts = channelId.split('_');
        if (parts.length >= 3) {
          uid = int.tryParse(parts[2]) ?? 0;
        }
      }
      if (uid <= 0) {
        uid = 10000 + (callResponse.callId > 0 ? callResponse.callId : 1);
      }

      if (token == null || token.isEmpty) {
        token = AgoraConstants.generateRtcToken(
          channelName: channelId,
          uid: uid,
        );
        debugPrint(
          '🔑 [HomeVM] Generated Agora RTC Token for channel "$channelId", UID $uid',
        );
      }

      debugPrint(
        '📞 [HomeVM] Joining Agora channel: channelId=$channelId, uid=$uid, hasToken=${token.isNotEmpty}',
      );

      // Clean up previous call session before joining
      await _agoraService.leaveCall();

      // 3. Join Agora Channel (Starts in Ringing / Calling state)
      bool joinSuccess = false;
      if (isVideo) {
        joinSuccess = await _agoraService.joinVideoCall(
          channelId: channelId,
          token: token,
          uid: uid,
        );
      } else {
        joinSuccess = await _agoraService.joinVoiceCall(
          channelId: channelId,
          token: token,
          uid: uid,
        );
      }

      if (joinSuccess) {
        // Start playing ringtone while waiting for agent to answer
        await _agoraService.playRingtone();
      }

      // If remote UID is already joined upon channel entry
      if (_agoraService.remoteUid != null) {
        _onAgentAttendedCall();
      }

      notifyListenersSafely();
    } catch (e) {
      debugPrint('⚠️ [HomeVM] Call start failed: $e');
      await _agoraService.stopRingtone();
      final msg = e.toString().replaceFirst(
        RegExp(r'^[A-Za-z0-9_]*Exception:\s*'),
        '',
      );
      setError(msg);
      _activeCallMatch = null;
      _isCallAttended = false;
      _wasLastCallConnected = false;
      _hasTriggeredLowCoinWarning = false;
      _remoteUserSub?.cancel();
      _remoteUserSub = null;
      notifyListenersSafely();
    }
  }

  /// Triggered strictly when the remote agent attends/answers the call
  void _onAgentAttendedCall() {
    _callStatusPollTimer?.cancel();
    _callStatusPollTimer = null;
    if (_isCallAttended || _activeCallMatch == null) return;
    _agoraService.stopRingtone();
    _isCallAttended = true;
    _wasLastCallConnected = true;
    debugPrint(
      '🎉 [HomeVM] Call attended! Starting timer and live coin deductions (5 coins/sec)...',
    );

    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeCallMatch == null) {
        timer.cancel();
        return;
      }
      _callDurationSeconds++;
      final matchRate = _activeCallMatch?.rateCoinsPerSec ?? 5;
      final rate = (matchRate <= 0 || matchRate == 3) ? 5 : matchRate;
      _callCoinsSpent += rate;
      // Deduct coins real-time from wallet in foreground and background
      _walletCoins = (_walletCoins - rate).clamp(0, 999999);

      // 1. When coins reach <= 300: Play warning beep sound once for alert
      if (_walletCoins <= 300 && !_hasTriggeredLowCoinWarning) {
        _hasTriggeredLowCoinWarning = true;
        debugPrint(
          '🔔 [HomeVM] Coin balance reached $_walletCoins coins (<= 300)! Playing alert beep...',
        );
        SoundService.playLowBalanceBeep();
      }

      // 2. When coins reach 0: Automatically cut/terminate the call
      if (_walletCoins <= 0) {
        debugPrint(
          '🛑 [HomeVM] Wallet coins depleted (0 coins)! Automatically cutting the call.',
        );
        timer.cancel();
        _callTimer = null;
        setError('Call ended: Your coin balance reached 0.');
        endCall(status: 'completed');
        return;
      }

      notifyListenersSafely();
    });

    notifyListenersSafely();
  }

  Future<void> endCall({String status = 'cancelled'}) async {
    _callTimer?.cancel();
    _callTimer = null;
    _callStatusPollTimer?.cancel();
    _callStatusPollTimer = null;
    _remoteUserSub?.cancel();
    _remoteUserSub = null;
    await _agoraService.stopRingtone();
    await _agoraService.leaveCall();

    final bool wasConnected = _isCallAttended || _callDurationSeconds > 0;
    _wasLastCallConnected = wasConnected;

    // Use actual call ID from _lastCallRequest, fallback to agent ID
    final targetCallId = _lastCallRequest?.callId != null && _lastCallRequest!.callId > 0
        ? _lastCallRequest!.callId
        : (_lastEndedCallId ?? int.tryParse(_activeCallMatch?.id ?? ''));

    if (targetCallId != null && targetCallId > 0) {
      _lastEndedCallId = targetCallId;
      final finalStatus = wasConnected
          ? 'completed'
          : (status == 'rejected' ? 'rejected' : 'cancelled');
      try {
        await _callRepository.updateCallStatus(
          callId: targetCallId,
          status: finalStatus,
        );
        debugPrint('📞 [HomeVM] Updated call status on server: callId=$targetCallId, status=$finalStatus');
      } catch (e) {
        debugPrint(
          '⚠️ [HomeVM] Update call status ($finalStatus) for ID $targetCallId failed: $e',
        );
      }
    }

    _activeCallMatch = null;
    _isCallAttended = false;
    _callDurationSeconds = 0;
    _callCoinsSpent = 0;
    _lastCallRequest = null;
    notifyListenersSafely();
    // Refresh coin balance and history after call ends
    fetchCoinsBalance(silent: true);
    fetchCallHistory(silent: true);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _agoraService.toggleMute(_isMuted);
    notifyListenersSafely();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _agoraService.toggleSpeaker(_isSpeakerOn);
    notifyListenersSafely();
  }

  Future<void> fetchCoinsBalance({bool silent = false, bool force = false}) async {
    if (!force &&
        _lastCoinsFetchTime != null &&
        DateTime.now().difference(_lastCoinsFetchTime!) <
            const Duration(seconds: 20)) {
      return;
    }
    _lastCoinsFetchTime = DateTime.now();
    try {
      final coins = await _userRepository.getCoinsBalance();
      _walletCoins = coins;
      _saveCachedCoins(coins);
      notifyListenersSafely();
    } catch (_) {
      // Keep existing balance if offline
    }
  }

  Future<bool> addCoins(int amount) async {
    // Optimistic update
    _walletCoins += amount;
    _saveCachedCoins(_walletCoins);
    notifyListenersSafely();

    try {
      final updatedBalance = await _userRepository.addCoins(amount);
      if (updatedBalance > 0) {
        _walletCoins = updatedBalance;
        _saveCachedCoins(_walletCoins);
      }
      notifyListenersSafely();
      return true;
    } catch (_) {
      // Revert if failed
      _walletCoins = (_walletCoins - amount).clamp(0, 999999);
      _saveCachedCoins(_walletCoins);
      notifyListenersSafely();
      return false;
    }
  }

  Future<void> fetchCoinHistory({bool silent = false, bool force = false}) async {
    if (!force &&
        _lastHistoryFetchTime != null &&
        DateTime.now().difference(_lastHistoryFetchTime!) <
            const Duration(seconds: 30)) {
      return;
    }
    _lastHistoryFetchTime = DateTime.now();

    final bool showLoader = !silent && _coinHistory == null;
    if (showLoader) {
      _isLoadingCoinHistory = true;
      notifyListenersSafely();
    }
    try {
      final history = await _userRepository.getCoinHistory();
      _coinHistory = history;
      if (history.currentBalance > 0) {
        _walletCoins = history.currentBalance;
        _saveCachedCoins(_walletCoins);
      }
    } catch (_) {
      // Keep existing history
    } finally {
      _isLoadingCoinHistory = false;
      notifyListenersSafely();
    }
  }

  Future<void> fetchUserProfile({bool silent = false, bool force = false}) async {
    if (!force &&
        _lastProfileFetchTime != null &&
        DateTime.now().difference(_lastProfileFetchTime!) <
            const Duration(seconds: 10)) {
      return;
    }
    _lastProfileFetchTime = DateTime.now();
    try {
      final profile = await _userRepository.getProfile();
      _userProfile = profile;
      debugPrint(
        '👤 [HomeViewModel] Caller Profile fetched from caller/profile/: name=${profile.fullName}, interests=${profile.interests}, calls=${profile.voiceCallsCount}, rating=${profile.rating}',
      );
      notifyListenersSafely();
    } catch (e) {
      debugPrint('⚠️ [HomeViewModel] Error fetching caller profile: $e');
    }
  }

  Future<bool> updateCallerProfile({
    required String name,
    int? age,
    String? language,
    List<String>? interests,
    String? bio,
  }) async {
    setLoading(true);
    try {
      final current = _userProfile ?? const UserProfile();
      final updated = current.copyWith(
        firstName: name.trim(),
        lastName: '',
        age: age,
        language: language?.trim().toLowerCase(),
        interests: interests ?? current.interests,
        bio: bio ?? current.bio,
      );
      final result = await _userRepository.updateProfile(updated);
      _userProfile = result;
      notifyListenersSafely();
      return true;
    } catch (e) {
      setError('Failed to update profile: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> uploadProfilePicture(File file) async {
    _userProfile =
        _userProfile?.copyWith(avatarUrl: file.path) ??
        UserProfile(avatarUrl: file.path);
    notifyListenersSafely();
    return true;
  }

  Future<void> init() async {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;

    // Seed immediate data from sync cache
    _role = _authRepository.currentRole ?? UserRole.user;
    _userProfile = _authRepository.currentUser;

    for (final m in _matches) {
      _allKnownMatches[m.id] = m;
    }
    for (final cat in _professions) {
      for (final m in cat.matches) {
        _allKnownMatches[m.id] = m;
      }
    }
    await _loadFavoritesFromStorage();

    try {
      _userProfile ??= _authRepository.currentUser;
      // Proactively sync fresh FCM token to backend for caller
      FcmService.sendFcmTokenToBackend();

      // Listen for token refresh events while caller is on home dashboard
      _fcmTokenSubscription?.cancel();
      _fcmTokenSubscription = FcmService.onTokenRefreshStream.listen((newToken) {
        debugPrint('🔄 [HomeViewModel] New FCM token received for caller: $newToken');
        FcmService.sendFcmTokenToBackend(newToken);
      });

      await Future.wait([
        fetchCategories(silent: false, force: true),
        fetchUserProfile(silent: true, force: true),
        fetchCoinsBalance(silent: true, force: true),
      ]);
    } catch (e) {
      setError(e.toString());
    } finally {
      _isInitialized = true;
      _isInitializing = false;
      notifyListenersSafely();
    }
  }

  Future<void> logout() async {
    endCall();
    setLoading(true);
    try {
      await _authRepository.logout();
    } catch (_) {}
    try {
      await TokenManager().clearTokens();
    } catch (_) {}
    _isLoggedOut = true;
    setLoading(false);
    notifyListenersSafely();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callStatusPollTimer?.cancel();
    _remoteUserSub?.cancel();
    _fcmTokenSubscription?.cancel();
    super.dispose();
  }
}
