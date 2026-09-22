// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:buddy_app/data/models/user_profile.dart';
import 'package:buddy_app/views/widgets/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/caller_intent_model.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/auth_api_repository.dart';
import '../../data/repositories/user_api_repository.dart';
import '../../viewmodels/home_view_model.dart';
import '../coins/coins_store_screen.dart';
import '../splash/splash_screen.dart';
import '../widgets/slide_to_action.dart';
import '../widgets/sparkle_widget.dart';
import 'widgets/agent_rating_bottom_sheet.dart';
import 'widgets/conversation_category_card.dart';
import 'widgets/edit_caller_profile_bottom_sheet.dart';
import 'widgets/live_call_bottom_sheet.dart';
import 'widgets/quick_intent_bottom_sheet.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      userRepository: UserApiRepository(),
      authRepository: AuthApiRepository(),
    );
    _viewModel.addListener(_handleStateChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.removeListener(_handleStateChange);
    super.dispose();
  }

  void _handleStateChange() {
    if (_viewModel.errorMessage != null &&
        _viewModel.errorMessage!.isNotEmpty) {
      showNeoToast(context, _viewModel.errorMessage!, isError: true);
      _viewModel.clearError();
    }
    if (_viewModel.isLoggedOut) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  void _onLogout() async {
    try {
      await _viewModel.logout();
    } catch (_) {
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _startCall(MatchProfile match) async {
    _viewModel.startCall(match);
    await LiveCallBottomSheet.show(context, _viewModel);

    // Only show rating sheet if the call was answered/connected by the listener
    if (mounted && _viewModel.wasLastCallConnected) {
      await AgentRatingBottomSheet.show(
        context,
        agentId: match.id,
        agentName: match.name,
        agentAvatar: match.avatarUrl,
        category: match.professionCategory,
        callId:
            _viewModel.lastEndedCallId ?? _viewModel.lastCallRequest?.callId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _viewModel.activeTab == 0 &&
          _viewModel.exploreStep == HomeExploreStep.intentSelection,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_viewModel.activeTab != 0) {
            _viewModel.setTab(0);
          } else if (_viewModel.exploreStep !=
              HomeExploreStep.intentSelection) {
            _viewModel.goBackInExplore();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // 1. Top-Right Soft Sage Circle (Wraps around status bar and Coin badge)
            Positioned(
              top: -65,
              right: -60,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  color: const Color(0xFFC3E2A0).withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 2. Middle-Left Warm Peach / Sand Organic Circle
            Positioned(
              top: 270,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D4AF).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 3. Bottom-Right Subtle Soft Lime Glow Circle
            Positioned(
              top: 500,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFFCEF17D).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main SafeArea Content
            SafeArea(
              bottom: false,
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Column(
                    children: [
                      // Top App Bar / Header
                      _buildTopHeader(),

                      // Tab Body
                      Expanded(
                        child: IndexedStack(
                          index: _viewModel.activeTab,
                          children: [
                            _buildExploreTab(),
                            CoinsStoreScreen(
                              viewModel: _viewModel,
                              isTab: true,
                            ),
                            _buildCallsTab(),
                            _buildProfileTab(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Floating Action Button for Category Multi-Selection
            Positioned(
              left: 24,
              right: 24,
              bottom: 96,
              child: SafeArea(
                top: false,
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) => _buildFloatingCategoryActionButton(),
                ),
              ),
            ),

            // Floating Bottom Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) => _buildFloatingBottomNav(),
                ),
              ),
            ),

            // Centered Circular Progress Indicator when loading API
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (!_viewModel.isLoading) return const SizedBox.shrink();
                return Container(
                  color: Colors.black.withOpacity(0.25),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.2,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(4, 4),
                        ),
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        strokeWidth: 3.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Phone + Heart Brand Logo & Tagline
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Phone + Heart Logo Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFFE11D48)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFFD1DC),
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTypography.brandLogo.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      children: const [
                        TextSpan(
                          text: 'GABBY ',
                          style: TextStyle(color: Color(0xFF0F2444)),
                        ),
                        TextSpan(
                          text: 'TALK',
                          style: TextStyle(color: Color(0xFF00A79D)),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Real People • Real Conversations',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: "You talk... We connect ❤️" & Coins
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your voice ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F2444).withOpacity(0.85),
                    ),
                  ),
                  const Text(
                    'matters! ❤️',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: () => _viewModel.setTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.6,
                    ),
                    boxShadow: AppTheme.neoShadow(
                      offset: const Offset(1.5, 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        '${_viewModel.walletCoins}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 0: Explore Flow (Direct to User List)
  Widget _buildExploreTab() {
    switch (_viewModel.exploreStep) {
      case HomeExploreStep.intentSelection:
        return _buildIntentSelectionStep();
      case HomeExploreStep.categoryMatches:
        return _buildCategoryMatchesStep();
    }
  }

  // STEP 1: "Choose what kind of listener you are" 2-Column Poster Screen
  Widget _buildIntentSelectionStep() {
    final intents = _viewModel.callerIntents;

    return RefreshIndicator(
      onRefresh: () async {
        await _viewModel.fetchCategories(force: true);
      },
      color: AppColors.strokeBlack,
      backgroundColor: AppColors.cardWhite,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 4,
          bottom: 200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 4),

            // Main Poster Headline
            const Text(
              'Choose what kind of listener you are',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F2444),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),

            // Poster Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Share your interests, background and what you enjoy — and be part of someone’s story.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2-Column Grid matching the 3D card layout
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intents.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.98,
              ),
              itemBuilder: (context, index) {
                final intent = intents[index];
                final isSelected = _viewModel.isIntentSelected(intent);
                return ConversationCategoryCard(
                  intent: intent,
                  isSelected: isSelected,
                  onTap: () => _viewModel.toggleIntentSelection(intent),
                );
              },
            ),
            const SizedBox(height: 22),

            // Bottom Poster Taglines with Decorative Wings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 1.5,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Different people  •  Different stories  •  Same goal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 1.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '— to make you feel better. ❤️ —',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // STEP 2: "Category Listeners & Matches" User List Screen
  Widget _buildCategoryMatchesStep() {
    final matches = _viewModel.filteredMatches;

    return RefreshIndicator(
      onRefresh: () async {
        await _viewModel.fetchCategories(force: true);
      },
      color: AppColors.strokeBlack,
      backgroundColor: AppColors.cardWhite,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 18,
          right: 18,
          top: 6,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _viewModel.goBackInExplore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 2.0,
                      ),
                      boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: AppColors.strokeBlack,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3E2A0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.8,
                    ),
                    boxShadow: AppTheme.neoShadow(
                      offset: const Offset(1.5, 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF15803D),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${matches.length} ${matches.length == 1 ? "Listener" : "Listeners"} Online',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Heading
            const Text(
              'Available Listeners 🌟',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F2444),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Ready to listen and connect with you right now.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),

            // Selected Topics Box
            if (_viewModel.selectedIntents.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected Topics (${_viewModel.selectedIntents.length}):',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBlack,
                          ),
                        ),
                        GestureDetector(
                          onTap: _viewModel.goBackInExplore,
                          child: const Text(
                            'Change Topics',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _viewModel.selectedIntents.map((intent) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: intent.badgeColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.4,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                intent.emoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                intent.title,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () =>
                                    _viewModel.removeSelectedIntent(intent.id),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.strokeBlack,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Search Bar
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _viewModel.setSearchQuery,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'Search listeners by name, topic, or bio...',
                  hintStyle: const TextStyle(
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.strokeBlack,
                    size: 20,
                  ),
                  suffixIcon: _viewModel.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.strokeBlack,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _viewModel.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick Filter: All vs Favorites
            Row(
              children: [
                _buildFilterPill(
                  label: 'All Listeners',
                  count: _viewModel.showFavoritesOnly
                      ? _viewModel.allMatchesCount
                      : matches.length,
                  isSelected: !_viewModel.showFavoritesOnly,
                  icon: Icons.people_rounded,
                  onTap: () {
                    if (_viewModel.showFavoritesOnly) {
                      _viewModel.toggleShowFavoritesOnly();
                    }
                  },
                ),
                const SizedBox(width: 10),
                _buildFilterPill(
                  label: 'Favorites',
                  count: _viewModel.favoritesCount,
                  isSelected: _viewModel.showFavoritesOnly,
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFFF4D6D),
                  onTap: () {
                    if (!_viewModel.showFavoritesOnly) {
                      _viewModel.toggleShowFavoritesOnly();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Matches Feed Cards or Loader
            if (_viewModel.isLoadingCategoryMatches ||
                _viewModel.isLoadingCategories)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 48,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2B2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.strokeBlack,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Discovering Listeners...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connecting to available listeners for your topics',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              )
            else if (matches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2B2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🔍', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _viewModel.showFavoritesOnly
                          ? 'No favorites found'
                          : 'No matching listeners found',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _viewModel.showFavoritesOnly
                          ? 'Tap the heart icon on any listener card to save favorites!'
                          : (_viewModel.discoverMessage ??
                                'No matching agents found for the selected topics.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textBlack.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _viewModel.goBackInExplore,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6F887),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 2.0,
                          ),
                          boxShadow: AppTheme.neoShadow(
                            offset: const Offset(2, 2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                              color: AppColors.strokeBlack,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Explore Other Topics',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  return _buildMatchCard(matches[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getCategoryImagePath(String id, String title) {
    final key = '${id.toLowerCase()} ${title.toLowerCase()}';
    if (key.contains('just_talk') ||
        key.contains('just talk') ||
        key.contains('conversation')) {
      return 'assets/images/categories/just_talk.png';
    } else if (key.contains('friendly') || key.contains('friendship')) {
      return 'assets/images/categories/friendly_conversation.png';
    } else if (key.contains('advice') || key.contains('perspective')) {
      return 'assets/images/categories/advice.png';
    } else if (key.contains('career') ||
        key.contains('motivation') ||
        key.contains('mentor') ||
        key.contains('work')) {
      return 'assets/images/categories/career.png';
    } else if (key.contains('travel') ||
        key.contains('guidance') ||
        key.contains('place')) {
      return 'assets/images/categories/travel.png';
    } else if (key.contains('elder') ||
        key.contains('companionship') ||
        key.contains('retired')) {
      return 'assets/images/categories/elder_companion.png';
    } else if (key.contains('student') ||
        key.contains('study') ||
        key.contains('college') ||
        key.contains('academics')) {
      return 'assets/images/categories/student_companion.jpg';
    } else if (key.contains('language') ||
        key.contains('listening') ||
        key.contains('english') ||
        key.contains('hindi')) {
      return 'assets/images/categories/language.png';
    } else {
      return 'assets/images/categories/casual.png';
    }
  }

  // TAB 1: All Matches Feed
  Widget _buildMatchesTab() {
    final matches = _viewModel.filteredMatches;

    return RefreshIndicator(
      onRefresh: () async {
        await _viewModel.fetchCategories(force: true);
      },
      color: AppColors.strokeBlack,
      backgroundColor: AppColors.cardWhite,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ALL MATCHES / FAVORITES Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _viewModel.showFavoritesOnly
                    ? const Color(0xFFFFD6E5) // Soft pink for favorites
                    : AppColors.accentLavender,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 1.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _viewModel.showFavoritesOnly
                          ? '❤️'
                          : (_viewModel.selectedIntent != null
                                ? _viewModel.selectedIntent!.emoji
                                : '✨'),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _viewModel.showFavoritesOnly
                                    ? 'MY FAVORITES'
                                    : (_viewModel.selectedIntent != null
                                          ? _viewModel.selectedIntent!.title
                                                .toUpperCase()
                                          : (_viewModel.selectedCategoryTitle !=
                                                    null
                                                ? _viewModel
                                                      .selectedCategoryTitle!
                                                      .toUpperCase()
                                                : 'ALL MATCHES')),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2B2), // Pale yellow
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.strokeBlack,
                                  width: 1.4,
                                ),
                              ),
                              child: Text(
                                '${matches.length} ${matches.length == 1 ? "match" : "matches"}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _viewModel.showFavoritesOnly
                              ? 'Showing all your saved favorites (${matches.length})'
                              : (_viewModel.selectedIntent != null
                                    ? 'Intent: ${_viewModel.selectedIntent!.title} (${_viewModel.selectedCategoryTitle}) • Tap to clear'
                                    : (_viewModel.selectedCategoryTitle != null
                                          ? 'Filtered by ${_viewModel.selectedCategoryTitle!} • Tap to clear'
                                          : 'Exploring all verified matches (${matches.length})')),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBlack.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_viewModel.selectedCategory != null &&
                      !_viewModel.showFavoritesOnly)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.strokeBlack,
                      ),
                      onPressed: _viewModel.clearCategoryFilter,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Filter: All Matches vs Favorites
            Row(
              children: [
                _buildFilterPill(
                  label: 'All Matches',
                  count: _viewModel.showFavoritesOnly
                      ? _viewModel.allMatchesCount
                      : matches.length,
                  isSelected: !_viewModel.showFavoritesOnly,
                  icon: Icons.people_rounded,
                  onTap: () {
                    if (_viewModel.showFavoritesOnly) {
                      _viewModel.toggleShowFavoritesOnly();
                    }
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterPill(
                  label: 'Favorites',
                  count: _viewModel.favoritesCount,
                  isSelected: _viewModel.showFavoritesOnly,
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFFF4D6D),
                  onTap: () {
                    if (!_viewModel.showFavoritesOnly) {
                      _viewModel.toggleShowFavoritesOnly();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Matches Feed Cards
            if (matches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
                ),
                child: Column(
                  children: [
                    const Text('💔', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      _viewModel.showFavoritesOnly
                          ? 'No favorites added yet'
                          : 'No matches found',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _viewModel.showFavoritesOnly
                          ? 'Tap the heart icon on any match card to save your favorites!'
                          : 'Try searching for a different profession or keyword.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  return _buildMatchCard(matches[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3064) : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.strokeBlack, width: 1.8),
          boxShadow: isSelected
              ? AppTheme.neoShadow(offset: const Offset(2.5, 2.5))
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (iconColor ?? AppColors.strokeBlack),
            ),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : AppColors.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchProfile match) {
    final isFav = _viewModel.isFavorite(match.id);

    // Pick high-resolution cartoon avatar based on match identity
    final hash = match.id.hashCode.abs();
    final isFemale = match.name.toLowerCase().endsWith('a') ||
        match.name.toLowerCase().endsWith('i') ||
        match.name.toLowerCase().endsWith('e') ||
        match.name.toLowerCase().contains('girl') ||
        (hash % 2 == 0);

    final avatarAsset = isFemale
        ? ((hash % 2 == 0)
            ? 'assets/images/avatar_female_1.jpg'
            : 'assets/images/avatar_female_2.jpg')
        : 'assets/images/avatar_male_1.jpg';

    // Meaningful bio fallback
    final bioText = (match.bio.trim().isEmpty ||
            match.bio.trim().toLowerCase() == 'jjjj' ||
            match.bio.trim().length < 4)
        ? 'Friendly listener ready for real conversations & emotional support ❤️'
        : match.bio.trim();

    return Container(
      decoration: BoxDecoration(
        color: match.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.strokeBlack, width: 2.2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(4, 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Badges Row
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Online & Rating Badge Group
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2B2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFE67E22),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            match.rating > 0
                                ? match.rating.toStringAsFixed(1)
                                : '5.0',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Rate Badge & Favorite Button Group
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${match.rateCoinsPerSec} Coins/s',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text('🪙', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final wasFav = _viewModel.isFavorite(match.id);
                        _viewModel.toggleFavorite(match.id, match);
                        showNeoToast(
                          context,
                          wasFav
                              ? 'Removed ${match.name} from favorites'
                              : 'Added ${match.name} to favorites ❤️',
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isFav
                              ? const Color(0xFFFF4D6D)
                              : AppColors.cardWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 1.5,
                          ),
                          boxShadow: AppTheme.neoShadow(
                            offset: const Offset(1.5, 1.5),
                          ),
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFav ? Colors.white : AppColors.strokeBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Beautiful Visual Showcase with Hero Avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              height: 155,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.strokeBlack, width: 2.0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle pastel background tint
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            match.avatarColor.withOpacity(0.18),
                            AppColors.cardWhite,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Decorative Corner Pill (Left): Language
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🗣️', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            match.location.contains('Language:')
                                ? match.location
                                      .replaceAll('Language:', '')
                                      .trim()
                                : 'English',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Decorative Corner Pill (Right): Instant
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6F887),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 12,
                            color: AppColors.strokeBlack,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Instant',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Avatar with Circle Frame & Shadow
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 2.2,
                      ),
                      boxShadow: AppTheme.neoShadow(
                        offset: const Offset(2.5, 2.5),
                      ),
                    ),
                    child: ClipOval(
                      child:
                          match.avatarUrl != null &&
                              match.avatarUrl!.isNotEmpty
                          ? Image.network(
                              match.avatarUrl!,
                              width: 105,
                              height: 105,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                avatarAsset,
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              avatarAsset,
                              width: 105,
                              height: 105,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),

                  // Sparkle decoration on top right of avatar
                  Positioned(
                    top: 16,
                    right: 95,
                    child: SparkleWidget(size: 16, color: match.avatarColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Name, Verified Tag & Topic Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${match.name}${match.age > 0 ? ', ${match.age}' : ''}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 20,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Specialty Badges Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.psychology_rounded,
                            size: 13,
                            color: Color(0xFF5A189A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.profession,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (match.professionCategory.isNotEmpty &&
                        match.professionCategory != match.profession)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD1E3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 1.3,
                          ),
                        ),
                        child: Text(
                          match.professionCategory,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bio Speech / Quote Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '❝ ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          bioText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textBlack,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Slide to Call Action Button
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
            child: SlideToActionButton(
              text: 'Slide to Call',
              icon: Icons.phone_rounded,
              height: 54,
              backgroundColor: const Color(0xFFF1FAC0),
              handleColor: const Color(0xFFD6F887),
              textColor: AppColors.strokeBlack,
              iconColor: AppColors.strokeBlack,
              onCompleted: () => _startCall(match),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Recent Voice Calls Log
  Widget _buildCallsTab() {
    final callLogs = _viewModel.callLogs;
    final isLoading = _viewModel.isLoadingCallHistory;

    return RefreshIndicator(
      onRefresh: () => _viewModel.fetchCallHistory(),
      color: AppColors.strokeBlack,
      backgroundColor: AppColors.cardWhite,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner: Recent Voice Calls 🎙️ 📞
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accentLavender,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Voice Calls 🎙️',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBlack,
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.strokeBlack,
                      ),
                    )
                  else
                    const Icon(
                      Icons.phone_in_talk_rounded,
                      color: AppColors.strokeBlack,
                      size: 22,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calls List or Empty State
            if (callLogs.isEmpty && !isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
                ),
                child: Column(
                  children: [
                    const Text('📞', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 14),
                    const Text(
                      'No call history yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your completed and incoming voice calls will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: callLogs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildCallCard(callLogs[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallCard(CallLogItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.strokeBlack, width: 2.0),
        boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.avatarColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeBlack, width: 1.6),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.strokeBlack,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.profession} ${item.professionEmoji}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.timeAgo} • ${item.callType}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E849E),
                  ),
                ),
              ],
            ),
          ),

          // Yellow Call Button
          GestureDetector(
            onTap: () {
              if (item.matchProfile != null) {
                _startCall(item.matchProfile!);
              } else {
                final match = _viewModel.filteredMatches.firstWhere(
                  (m) => m.name.toLowerCase() == item.name.toLowerCase(),
                  orElse: () => _viewModel.filteredMatches.first,
                );
                _startCall(match);
              }
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7CE), // Pale yellow
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.strokeBlack, width: 1.6),
              ),
              child: const Icon(
                Icons.phone_rounded,
                color: AppColors.strokeBlack,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Profile & Settings
  Widget _buildProfileTab() {
    final profile = _viewModel.userProfile;
    final displayName = (profile != null && profile.firstName.isNotEmpty)
        ? (profile.age != null
              ? '${profile.fullName}, ${profile.age}'
              : profile.fullName)
        : 'User';

    final subtitleParts = <String>[];
    if (profile?.profession != null && profile!.profession!.isNotEmpty) {
      subtitleParts.add(profile.profession!);
    }
    if (profile?.location != null && profile!.location!.isNotEmpty) {
      subtitleParts.add(profile.location!);
    }
    if (profile?.language != null && profile!.language!.isNotEmpty) {
      final lang = profile!.language!;
      subtitleParts.add(
        lang.length > 1
            ? (lang[0].toUpperCase() + lang.substring(1))
            : lang.toUpperCase(),
      );
    }
    if (profile?.gender != null && profile!.gender!.displayName.isNotEmpty) {
      subtitleParts.add(profile!.gender!.displayName);
    }
    final subtitleText = subtitleParts.isNotEmpty
        ? subtitleParts.join(' • ')
        : 'Gabby Talk Caller ✨';

    final bioText = (profile?.bio != null && profile!.bio!.isNotEmpty)
        ? profile.bio!
        : 'Connecting with friendly companions through real-time voice calls 🎧✨';

    final voiceCallsCount = profile?.voiceCallsCount ?? 0;
    final ratingVal = (profile?.rating ?? 5.0).toStringAsFixed(1);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _viewModel.fetchUserProfile(force: true),
          _viewModel.fetchCoinsBalance(force: true),
        ]);
      },
      color: AppColors.strokeBlack,
      backgroundColor: AppColors.cardWhite,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 130,
        ),
        child: Column(
          children: [
            // Top Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Column(
                children: [
                  // Avatar with Camera Badge (Tappable for Gallery / Camera Upload)
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFAEC4FE),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.8,
                            ),
                          ),
                          child: ClipOval(
                            child: _buildAvatarImage(profile?.avatarUrl),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7CE),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 1.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: AppColors.strokeBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name & Age with Quick Edit Badge
                  GestureDetector(
                    onTap: () =>
                        EditCallerProfileBottomSheet.show(context, _viewModel),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6F887),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: AppColors.strokeBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Profession / Language Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCE8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      subtitleText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bio
                  Text(
                    bioText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B2D42),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3 Stats Boxes Row
                  Row(
                    children: [
                      // Favorites Box
                      Expanded(
                        child: _buildStatBox(
                          icon: Icons.favorite,
                          emoji: null,
                          value: '${_viewModel.favoritesCount}',
                          label: 'Favorites',
                          bgColor: const Color(0xFFFFB7D5),
                          onTap: () {
                            _viewModel.setTab(1);
                            if (!_viewModel.showFavoritesOnly) {
                              _viewModel.toggleShowFavoritesOnly();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Voice Calls Box
                      Expanded(
                        child: _buildStatBox(
                          icon: Icons.phone_rounded,
                          emoji: null,
                          value: '$voiceCallsCount',
                          label: 'Voice Calls',
                          bgColor: const Color(0xFFB8C4FE),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Rating Box
                      Expanded(
                        child: _buildStatBox(
                          icon: Icons.star_rounded,
                          emoji: null,
                          value: ratingVal,
                          label: 'Rating',
                          bgColor: const Color(0xFFFFF7CE),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu / Settings Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.credit_card_rounded,
                    title:
                        'My Coin Wallet 🪙 (${_viewModel.walletCoins} Coins)',
                    onTap: () => _viewModel.setTab(1),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1.5,
                    color: AppColors.strokeBlack,
                  ),
                  _buildMenuItem(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile ✏️',
                    onTap: () {
                      EditCallerProfileBottomSheet.show(context, _viewModel);
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1.5,
                    color: AppColors.strokeBlack,
                  ),
                  _buildMenuItem(
                    icon: Icons.security_rounded,
                    title: 'Privacy & Security 🔐',
                    onTap: () {},
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1.5,
                    color: AppColors.strokeBlack,
                  ),
                  _buildMenuItem(
                    icon: Icons.exit_to_app_rounded,
                    title: 'Log Out 🚪',
                    onTap: _onLogout,
                  ),
                  // Delete Account button commented out as requested
                  /*
                  const Divider(
                    height: 1,
                    thickness: 1.5,
                    color: AppColors.strokeBlack,
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Account 🗑️',
                    isDestructive: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account?'),
                          content: const Text(
                            'Are you sure you want to delete your Gabby Talk account? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _onLogout();
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.errorRed),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  */
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatInterestTag(String tag) {
    final lower = tag.toLowerCase().trim();
    if (lower.contains('philosophy')) return '🏛️ Philosophy & Life';
    if (lower.contains('business') || lower.contains('startup')) {
      return '💼 Business & Startups';
    }
    if (lower.contains('art') || lower.contains('design')) {
      return '🎨 Art & Design';
    }
    if (lower.contains('fitness') || lower.contains('gym')) {
      return '💪 Fitness & Gym';
    }
    if (lower.contains('tech') ||
        lower.contains('coding') ||
        lower.contains('software')) {
      return '💻 Tech & Coding';
    }
    if (lower.contains('food') || lower.contains('cook')) {
      return '🍳 Food & Cooking';
    }
    if (lower.contains('music') || lower.contains('sing')) {
      return '🎵 Music & Songs';
    }
    if (lower.contains('movie') || lower.contains('cinema')) {
      return '🎬 Movies & Cinema';
    }
    if (lower.contains('travel')) return '✈️ Travel & Explore';
    if (lower.contains('gaming') || lower.contains('game')) return '🎮 Gaming';
    if (lower.contains('book') || lower.contains('read')) {
      return '📚 Books & Reading';
    }
    if (lower.contains('photo')) return '📸 Photography';
    if (lower.contains('sports') ||
        lower.contains('cricket') ||
        lower.contains('football')) {
      return '⚽ Sports';
    }

    // Default capitalize
    return tag
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  Widget _buildAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return const Icon(Icons.person, size: 52, color: AppColors.strokeBlack);
    }
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return Image.network(
        avatarUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person, size: 52, color: AppColors.strokeBlack),
      );
    }
    // Local file path
    final file = File(avatarUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person, size: 52, color: AppColors.strokeBlack),
      );
    }
    return const Icon(Icons.person, size: 52, color: AppColors.strokeBlack);
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.strokeBlack, width: 2.5),
            left: BorderSide(color: AppColors.strokeBlack, width: 2.5),
            right: BorderSide(color: AppColors.strokeBlack, width: 2.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Profile Picture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.strokeBlack,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImagePickerOption(
                icon: Icons.photo_library_rounded,
                title: 'Choose from Gallery',
                subtitle: 'Select an existing photo from device files',
                bgColor: const Color(0xFFB8C4FE),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              _buildImagePickerOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take a Photo',
                subtitle: 'Use your camera to capture a new photo',
                bgColor: const Color(0xFFFFF7CE),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        final file = File(pickedFile.path);
        await _viewModel.uploadProfilePicture(file);
        if (mounted) {
          showNeoToast(context, 'Profile picture updated! ✨');
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('MissingPluginException')) {
          showNeoToast(
            context,
            'Please restart/rebuild the app to enable camera & gallery permissions.',
            isError: true,
          );
        } else if (errStr.contains('permission_denied') ||
            errStr.contains('denied')) {
          showNeoToast(
            context,
            'Permission denied. Please grant photos/camera permission in settings.',
            isError: true,
          );
        } else {
          showNeoToast(context, 'Unable to pick image: $e', isError: true);
        }
      }
    }
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.strokeBlack, width: 2.0),
          boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.strokeBlack, width: 1.8),
              ),
              child: Icon(icon, size: 22, color: AppColors.strokeBlack),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.strokeBlack,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.strokeBlack, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textBlack,
        ),
      ),
    );
  }

  Widget _buildStatBox({
    IconData? icon,
    String? emoji,
    required String value,
    required String label,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.strokeBlack, width: 1.8),
          boxShadow: onTap != null
              ? AppTheme.neoShadow(offset: const Offset(2, 2))
              : null,
        ),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, size: 20, color: AppColors.strokeBlack)
            else if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final itemColor = isDestructive ? AppColors.errorRed : AppColors.textBlack;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: itemColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: itemColor, size: 20),
          ],
        ),
      ),
    );
  }

  // Floating Action Button for Category Multi-Selection
  Widget _buildFloatingCategoryActionButton() {
    final bool isVisible =
        _viewModel.activeTab == 0 &&
        _viewModel.exploreStep == HomeExploreStep.intentSelection &&
        _viewModel.selectedIntents.isNotEmpty;

    if (!isVisible) return const SizedBox.shrink();

    final count = _viewModel.selectedIntents.length;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewModel.submitSelectedIntents(),
            borderRadius: BorderRadius.circular(32),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2444), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2444).withOpacity(0.38),
                    offset: const Offset(0, 6),
                    blurRadius: 16,
                  ),
                  const BoxShadow(
                    color: Colors.black26,
                    offset: Offset(3, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge counter + Action Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC3E2A0), // Pastel Lime/Sage
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$count selected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F2444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Find Listeners',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),

                  // Forward Arrow Button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Color(0xFF0F2444),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Floating Bottom Navigation Bar (4 items)
  Widget _buildFloatingBottomNav() {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.strokeBlack, width: 2.2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, icon: Icons.grid_view_rounded),
          _buildNavItem(index: 1, icon: Icons.toll_rounded),
          _buildNavItem(index: 2, icon: Icons.phone_rounded),
          _buildNavItem(index: 3, icon: Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon}) {
    final isSelected = _viewModel.activeTab == index;

    return GestureDetector(
      onTap: () => _viewModel.setTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLavender : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.strokeBlack, width: 1.8)
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: AppColors.strokeBlack),
      ),
    );
  }
}
