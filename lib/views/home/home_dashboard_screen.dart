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
        backgroundColor: const Color(0xFFFBF8EE),
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
              // Gabby Talk Official Brand Logo Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(1.5, 1.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/gabby_talk_logo.png',
                    fit: BoxFit.cover,
                  ),
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
                          text: 'GABY ',
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
                    'You talk... ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F2444).withOpacity(0.85),
                    ),
                  ),
                  const Text(
                    'We connect ❤️',
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

            // Main Poster Headline matching image
            const Text(
              'What would you like to talk about today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F2444),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 5),

            // Poster Subtitle matching image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Choose a category that feels right for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.topRight,
                child: TextButton(onPressed: (){
                  _viewModel.selectAllIntents();
                }, child: Text("Select All"))),
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

            // Bottom Poster Tagline matching image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 1.5,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          "There's always someone here for you",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 1.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 1.5,
                        color: const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFF15B70),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 16,
                        height: 1.5,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ],
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
            // Top Navigation: Back Button
            GestureDetector(
              onTap: _viewModel.goBackInExplore,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.0),
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.55,
                ),
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
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 120,
        ),
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
                separatorBuilder: (_, _) => const SizedBox(height: 14),
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

    // Display ONLY the agent's interests in the interest box
    final String interestDisplay = match.interests.isNotEmpty
        ? match.interests.join(' • ')
        : (match.conversationCategoryNames.isNotEmpty
              ? match.conversationCategoryNames.join(' • ')
              : (match.professionCategory.isNotEmpty &&
                        match.professionCategory != 'General' &&
                        match.professionCategory != match.profession
                    ? match.professionCategory
                    : (match.bio.trim().isNotEmpty &&
                              match.bio.trim().length > 3
                          ? match.bio.trim()
                          : match.profession)));

    return Container(
      decoration: BoxDecoration(
        color: match.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.strokeBlack, width: 1.2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Badges Row
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
                        horizontal: 4,
                        vertical: 2,
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
                                : '0',
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
              ],
            ),
          ),
          const SizedBox(height: 7),
          // Rate Badge & Favorite Button Group
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 1),
            child: Row(
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
          ),
          const SizedBox(height: 10),
          // 2. Beautiful Visual Showcase with Hero Avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              height: 135,
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
                          const Text('🗣️', style: TextStyle(fontSize: 8)),
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
                  // Positioned(
                  //   top: 12,
                  //   right: 10,
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 3,
                  //     ),
                  //     decoration: BoxDecoration(
                  //       color: const Color(0xFFD6F887),
                  //       borderRadius: BorderRadius.circular(10),
                  //       border: Border.all(
                  //         color: AppColors.strokeBlack,
                  //         width: 1.2,
                  //       ),
                  //     ),
                  //     child: const Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(
                  //           Icons.bolt_rounded,
                  //           size: 12,
                  //           color: AppColors.strokeBlack,
                  //         ),
                  //         SizedBox(width: 2),
                  //         Text(
                  //           'Instant',
                  //           style: TextStyle(
                  //             fontSize: 10,
                  //             fontWeight: FontWeight.w900,
                  //             color: AppColors.textBlack,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  // Center Gender Image with Circle Frame & Shadow (No DP)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: match.isFemale
                          ? const Color(0xFFFFF0F5)
                          : const Color(0xFFF0F9FF),
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
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          match.genderImageAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Sparkle decoration on top right of avatar
                  // Positioned(
                  //   top: 12,
                  //   right: 90,
                  //   child: SparkleWidget(size: 16, color: match.avatarColor),
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Profession Badge (Only show the profession, e.g. Doctor)
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
                      ClipOval(
                        child: Image.asset(
                          match.genderImageAsset,
                          width: 16,
                          height: 16,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
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
                const SizedBox(height: 4),

                // Interests Box with "Interests" heading & all user interests
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 10,
                //     vertical: 6,
                //   ),
                //   decoration: BoxDecoration(
                //     color: AppColors.cardWhite.withOpacity(0.92),
                //     borderRadius: BorderRadius.circular(14),
                //     border: Border.all(
                //       color: AppColors.strokeBlack,
                //       width: 1.4,
                //     ),
                //   ),
                //   child: Row(
                //     crossAxisAlignment: CrossAxisAlignment.center,
                //     children: [
                //       Container(
                //         padding: const EdgeInsets.symmetric(
                //           horizontal: 7,
                //           vertical: 2.5,
                //         ),
                //         decoration: BoxDecoration(
                //           color: const Color(0xFFFFD1E3),
                //           borderRadius: BorderRadius.circular(8),
                //           border: Border.all(
                //             color: AppColors.strokeBlack,
                //             width: 1.1,
                //           ),
                //         ),
                //         child: const Text(
                //           'Interests',
                //           style: TextStyle(
                //             fontSize: 10.5,
                //             fontWeight: FontWeight.w900,
                //             color: AppColors.textBlack,
                //           ),
                //         ),
                //       ),
                //       const SizedBox(width: 8),
                //       Expanded(
                //         child: Text(
                //           interestDisplay,
                //           maxLines: 2,
                //           overflow: TextOverflow.ellipsis,
                //           style: const TextStyle(
                //             fontSize: 12,
                //             fontWeight: FontWeight.w800,
                //             color: AppColors.textBlack,
                //             height: 1.25,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // 4. Slide to Call Action Button
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
            child: SlideToActionButton(
              text: 'Slide to Call',
              icon: Icons.phone_rounded,
              height: 35,
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
          bottom: 130,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Lavender Title Pill with 3px Black Stroke: 'Recent Voice Calls'
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFD6D7FF), // Lavender title pill
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.strokeBlack,
                  width: 3.0, // 3px black stroke
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.strokeBlack,
                    offset: Offset(4, 4), // Hard drop shadow
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('🎙️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'Recent Voice Calls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_rounded,
                        color: AppColors.strokeBlack,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Center Large White Neubrutalist Card (No call history yet)
            if (callLogs.isEmpty && !isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 42,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.strokeBlack,
                    width: 3.0, // 3px black outline
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.strokeBlack,
                      offset: Offset(4, 4), // Hard drop shadow
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Retro Telephone Handset Icon (2D Cartoon)
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7CE), // Pastel yellow
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 3.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.strokeBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBAE6FD), // Pastel blue
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 2.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons
                              .phone_in_talk_rounded, // Retro telephone handset
                          size: 32,
                          color: AppColors.strokeBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Bold headline: 'No call history yet'
                    const Text(
                      'No call history yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtext: 'Your completed and incoming voice calls will appear here.'
                    Text(
                      'Your completed and incoming voice calls will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack.withOpacity(0.70),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Explore Listeners CTA Button
                    GestureDetector(
                      onTap: () => _viewModel.setTab(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5EBAA), // Pastel mint green
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.strokeBlack,
                              offset: Offset(2.5, 2.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore Listeners',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textBlack,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text('✨', style: TextStyle(fontSize: 16)),
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
    final isFemale =
        item.name.toLowerCase().endsWith('a') ||
        item.name.toLowerCase().endsWith('i') ||
        item.name.toLowerCase().endsWith('e') ||
        item.matchProfile?.isFemale == true;

    final avatarAsset = isFemale
        ? 'assets/images/avatar_female_1.jpg'
        : 'assets/images/avatar_male_1.jpg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.strokeBlack, width: 1.8),
        boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
      ),
      child: Row(
        children: [
          // Round Gender Image (No DP)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isFemale
                  ? const Color(0xFFFFF0F5)
                  : const Color(0xFFF0F9FF),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeBlack, width: 1.8),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  item.matchProfile != null
                      ? item.matchProfile!.genderImageAsset
                      : (isFemale
                            ? 'assets/images/Girl.png'
                            : 'assets/images/Boy.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF7E849E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.timeAgo} • ${item.duration}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7E849E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Colored Quick Call Button
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.avatarColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                boxShadow: AppTheme.neoShadow(offset: const Offset(1.5, 1.5)),
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

  // TAB 3: User Profile & Settings
  Widget _buildProfileTab() {
    final profile = _viewModel.userProfile;
    final displayName = (profile != null && profile.firstName.isNotEmpty)
        ? (profile.age != null
              ? '${profile.fullName}, ${profile.age}'
              : profile.fullName)
        : 'Tester, 29';

    final langStr = (profile?.language != null && profile!.language!.isNotEmpty)
        ? (profile.language!.length > 1
              ? (profile.language![0].toUpperCase() +
                    profile.language!.substring(1))
              : profile.language!.toUpperCase())
        : 'English';
    final genderStr =
        (profile?.gender != null && profile!.gender!.displayName.isNotEmpty)
        ? profile.gender!.displayName
        : 'Man';
    final subtitleText = '$langStr • $genderStr';

    final bioText = (profile?.bio != null && profile!.bio!.isNotEmpty)
        ? profile.bio!
        : 'Connecting with friendly companions through real-time voice calls 🎧✨';

    final voiceCallsCount = profile?.voiceCallsCount ?? 0;
    final ratingVal = (profile?.rating ?? 0.0).toStringAsFixed(1);

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
          top: 6,
          bottom: 130,
        ),
        child: Column(
          children: [
            // 1. Main Top Profile Card with 3px Black Border & Hard Shadow
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.strokeBlack,
                  width: 3.0, // 3px black border
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.strokeBlack,
                    offset: Offset(4, 4), // Hard drop shadow
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Blue circle user avatar with camera badge
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFBAE6FD,
                            ), // Blue circle avatar container
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 3.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.strokeBlack,
                                offset: Offset(2.5, 2.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildAvatarImage(profile?.avatarUrl),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFF7CE,
                              ), // Pastel yellow camera badge
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 2.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.strokeBlack,
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: AppColors.strokeBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // User name 'Tester, 29' with edit pencil
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
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5EBAA), // Pastel mint green
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 2.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.strokeBlack,
                                offset: Offset(1.5, 1.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: AppColors.strokeBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Pill reading 'English • Man'
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7CE), // Pastel yellow pill
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 2.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.strokeBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      subtitleText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bio Text
                  Text(
                    bioText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack.withOpacity(0.70),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3 Small Stat Cards in Pink, Blue, and Yellow
                  Row(
                    children: [
                      // 1. Pink: '0 Favorites'
                      Expanded(
                        child: _buildStatBox(
                          icon: Icons.favorite_rounded,
                          value: '${_viewModel.favoritesCount}',
                          label: 'Favorites',
                          bgColor: const Color(0xFFFFB7D5), // Pastel pink
                          onTap: () {
                            _viewModel.setTab(1);
                            if (!_viewModel.showFavoritesOnly) {
                              _viewModel.toggleShowFavoritesOnly();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 2. Blue: '0 Voice Calls'
                      Expanded(
                        child: _buildStatBox(
                          icon: Icons.phone_rounded,
                          value: '$voiceCallsCount',
                          label: 'Voice Calls',
                          bgColor: const Color(0xFFBAE6FD), // Pastel blue
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 3. Yellow: '0.0 Rating'
                      Expanded(
                        child: _buildStatBox(
                          icon: Icons.star_rounded,
                          value: ratingVal,
                          label: 'Rating',
                          bgColor: const Color(0xFFFFF7CE), // Pastel yellow
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. White Settings Menu Block with 3px Black Border & Hard Shadow
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppColors.strokeBlack,
                  width: 3.0, // 3px black border
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.strokeBlack,
                    offset: Offset(4, 4), // Hard drop shadow
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'My Coin Wallet',
                    onTap: () => _viewModel.setTab(1),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 2.0,
                    color: AppColors.strokeBlack,
                  ),
                  _buildMenuItem(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    onTap: () {
                      EditCallerProfileBottomSheet.show(context, _viewModel);
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 2.0,
                    color: AppColors.strokeBlack,
                  ),
                  _buildMenuItem(
                    icon: Icons.security_rounded,
                    title: 'Privacy & Security',
                    onTap: () {},
                  ),
                  const Divider(
                    height: 1,
                    thickness: 2.0,
                    color: AppColors.strokeBlack,
                  ),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    onTap: _onLogout,
                  ),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.strokeBlack,
            width: 2.4, // 2.5px neubrutalist border
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.strokeBlack,
              offset: Offset(3, 3), // Hard offset drop shadow
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, size: 22, color: AppColors.strokeBlack)
            else if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
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
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7CE),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.strokeBlack, width: 1.8),
              ),
              child: Icon(icon, color: itemColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: itemColor,
                ),
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
        border: Border.all(
          color: AppColors.strokeBlack,
          width: 3.0, // 3px black outline
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.strokeBlack,
            offset: Offset(4, 4), // Hard drop shadow
            blurRadius: 0,
          ),
        ],
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
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD6D7FF)
              : Colors.transparent, // Highlighted with lavender
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.strokeBlack, width: 2.2)
              : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.strokeBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: AppColors.strokeBlack),
      ),
    );
  }
}
