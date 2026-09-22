// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/agent_rating_model.dart';
import '../../data/repositories/auth_api_repository.dart';
import '../../viewmodels/agent_dashboard_view_model.dart';
import '../call/audio_call_screen.dart';
import '../splash/splash_screen.dart';
import 'agent_profile_screen.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen>
    with WidgetsBindingObserver {
  late final AgentDashboardViewModel _viewModel;
  late final TextEditingController _displayNameController;
  late final TextEditingController _languagesController;
  late final TextEditingController _bioController;
  bool _isAcceptingCall = false;

  final List<String> _professionsList = [
    'Friendly Chat, Emotional Support',
    'Relationship & Dating Advice',
    'Life Coaching & Motivation',
    'Software Engineer',
    'Doctor',
    'Lawyer',
    'Writer',
    'Chef',
    'Photographer',
    'Marketing Specialist',
    'Journalist',
    'Pilot',
  ];

  List<String> get _effectiveProfessionsList {
    final list = List<String>.from(_professionsList);
    if (_viewModel.selectedProfession.trim().isNotEmpty &&
        !list.contains(_viewModel.selectedProfession.trim())) {
      list.insert(0, _viewModel.selectedProfession.trim());
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = AgentDashboardViewModel(authRepository: AuthApiRepository());
    _displayNameController = TextEditingController(
      text: _viewModel.displayName,
    );
    _languagesController = TextEditingController(text: _viewModel.languages);
    _bioController = TextEditingController(text: _viewModel.bio);

    _viewModel.addListener(_syncControllersWithViewModel);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        '📱 [AgentDashboard] App resumed from background -> checking pending incoming calls and syncing stats',
      );
      _viewModel.checkPendingIncomingCallsAndRefresh();
    }
  }

  bool _wasIncomingCall = false;

  void _syncControllersWithViewModel() {
    if (_viewModel.hasIncomingCall && !_wasIncomingCall) {
      _wasIncomingCall = true;
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    } else if (!_viewModel.hasIncomingCall) {
      _wasIncomingCall = false;
    }

    if (_displayNameController.text != _viewModel.displayName &&
        _viewModel.displayName.isNotEmpty) {
      _displayNameController.text = _viewModel.displayName;
    }
    if (_languagesController.text != _viewModel.languages &&
        _viewModel.languages.isNotEmpty) {
      _languagesController.text = _viewModel.languages;
    }
    if (_bioController.text != _viewModel.bio && _viewModel.bio.isNotEmpty) {
      _bioController.text = _viewModel.bio;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_syncControllersWithViewModel);
    _displayNameController.dispose();
    _languagesController.dispose();
    _bioController.dispose();
    _viewModel.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Top-Right Soft Sage Circle
          Positioned(
            top: -65,
            right: -60,
            child: Container(
              width: 270,
              height: 270,
              decoration: const BoxDecoration(
                color: Color(0xFFC3E2A0),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Middle-Left Warm Peach Circle
          Positioned(
            top: 270,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                color: Color(0xFFE8D4AF),
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
              decoration: const BoxDecoration(
                color: Color(0xFFCEF17D),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return Column(
                  children: [
                    // Top App Bar
                    _buildAgentTopBar(),

                    // Shared Agent Profile Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildAgentProfileCard(),
                    ),
                    const SizedBox(height: 12),

                    // Active Tab Body
                    Expanded(
                      child: IndexedStack(
                        index: _viewModel.activeTab,
                        children: [
                          _buildWorkbenchTab(),
                          _buildEarningsTab(),
                          _buildAgentFormTab(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Floating Bottom Navigation Bar (3 items)
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
                      boxShadow: AppTheme.neoShadow(offset: const Offset(4, 4)),
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

          // Full-Screen Incoming Caller Overlay (Triggered by FCM Notification)
          _buildIncomingCallFullScreenOverlay(),
        ],
      ),
    );
  }

  // Full-Screen Incoming Caller Overlay Widget
  Widget _buildIncomingCallFullScreenOverlay() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (!_viewModel.hasIncomingCall) return const SizedBox.shrink();

        return Container(
          color: Colors.black.withOpacity(0.88),
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Live Incoming Call Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4D6D).withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'INCOMING AUDIO CALL 🔔',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center: Caller Profile & Topic
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Concentric Ring Glowing Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD1E3),
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB7D5).withOpacity(0.4),
                            blurRadius: 28,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🎧', style: TextStyle(fontSize: 52)),
                    ),
                    const SizedBox(height: 24),

                    // Caller Name
                    Text(
                      _viewModel.callerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Topic / Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLavender,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.8,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(2, 2),
                        ),
                      ),
                      child: Text(
                        _viewModel.callTopic,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Earning Rate Notice
                    Text(
                      'Rate: ${_viewModel.selectedRate} Coins / sec',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF06D6A0),
                      ),
                    ),
                  ],
                ),

                // Bottom Action Buttons: Decline (Red) & Accept (Green)
                Row(
                  children: [
                    // Decline Call Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await _viewModel.declineCall();
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF476F),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF476F).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_end_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Decline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Accept Call Button
                    Expanded(
                      child: GestureDetector(
                        onTap: _isAcceptingCall
                            ? null
                            : () async {
                                setState(() {
                                  _isAcceptingCall = true;
                                });
                                try {
                                  final callModel = await _viewModel
                                      .acceptCall();
                                  if (callModel != null && mounted) {
                                    await AudioCallScreen.start(
                                      context,
                                      callModel,
                                    );
                                    if (mounted) {
                                      _viewModel.refresh();
                                    }
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isAcceptingCall = false;
                                    });
                                  }
                                }
                              },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06D6A0).withOpacity(0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isAcceptingCall
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Connecting...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.call_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Accept',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Top App Bar: GABBY TALK AGENT + DUTY TOGGLE
  Widget _buildAgentTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo: GabbyTalk AGENT
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: AppTypography.brandLogo.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Gabby',
                      style: TextStyle(color: Color(0xFF0F3064)),
                    ),
                    TextSpan(
                      text: 'Talk ',
                      style: TextStyle(color: Color(0xFF00A79D)),
                    ),
                  ],
                ),
              ),
              const Text(
                'AGENT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFFFF8DA1), // Pink highlight
                ),
              ),
            ],
          ),

          // Right Controls: Refresh Button + DUTY Pill
          Row(
            children: [
              GestureDetector(
                onTap: () => _viewModel.refresh(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.8,
                    ),
                    boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.strokeBlack,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _viewModel.isTogglingDuty ? null : _viewModel.toggleDuty,
                child: Opacity(
                  opacity: _viewModel.isTogglingDuty ? 0.6 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 1.8,
                      ),
                      boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _viewModel.isDutyOn
                                ? const Color(0xFF22C55E)
                                : AppColors.errorRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _viewModel.isDutyOn ? 'DUTY: ON' : 'DUTY: OFF',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shared Agent Profile Card (Lavender)
  Widget _buildAgentProfileCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgentProfileScreen(viewModel: _viewModel),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentLavender,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.strokeBlack, width: 2.2),
          boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
        ),
        child: Column(
          children: [
            // Top Row: Avatar, Name, Rating
            Row(
              children: [
                // Avatar with Profile Image or Headset Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCE8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.8,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        (_viewModel.profilePicture != null &&
                            _viewModel.profilePicture!.isNotEmpty &&
                            _viewModel.profilePicture!.startsWith('http'))
                        ? Image.network(
                            _viewModel.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.headset_mic_rounded,
                              size: 26,
                              color: AppColors.strokeBlack,
                            ),
                          )
                        : const Icon(
                            Icons.headset_mic_rounded,
                            size: 26,
                            color: AppColors.strokeBlack,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Profession
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _viewModel.agentName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.strokeBlack,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 1.4,
                              ),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _viewModel.profession,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Catchy Neo Rating Badge (Yellow Amber Glow)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFDE59,
                    ), // Rich golden sunshine yellow
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.0,
                    ),
                    boxShadow: AppTheme.neoShadow(
                      offset: const Offset(2.2, 2.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: AppColors.strokeBlack,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _viewModel.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (_viewModel.ratingData != null &&
                          _viewModel.ratingData!.totalReviews > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '(${_viewModel.ratingData!.totalReviews})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textBlack.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Thin Divider
            Container(
              height: 1.2,
              color: AppColors.strokeBlack.withOpacity(0.25),
            ),
            const SizedBox(height: 10),

            // 3 Metric Counters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                  'TODAY EARNED',
                  '${_viewModel.todayEarned} 🪙',
                ),
                Container(
                  height: 24,
                  width: 1.2,
                  color: AppColors.strokeBlack.withOpacity(0.25),
                ),
                _buildMetricColumn(
                  'TOTAL CALLS',
                  '${_viewModel.totalCalls} 📞',
                ),
                Container(
                  height: 24,
                  width: 1.2,
                  color: AppColors.strokeBlack.withOpacity(0.25),
                ),
                _buildMetricColumn('DUTY TIME', '${_viewModel.dutyTime} ⏱️'),
              ],
            ),
            const SizedBox(height: 12),

            // Catchy View Profile & Reviews Action Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCE8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.strokeBlack, width: 1.6),
                boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 15,
                    color: Color(0xFFFF9F1C),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _viewModel.ratingData != null &&
                              _viewModel.ratingData!.totalReviews > 0
                          ? '⭐ VIEW ${_viewModel.rating.toStringAsFixed(1)} RATING & ${_viewModel.ratingData!.totalReviews} REVIEWS'
                          : '⭐ VIEW PROFILE & CALLER REVIEWS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: AppColors.strokeBlack,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textBlack,
          ),
        ),
      ],
    );
  }

  // TAB 0: Active Call Workbench
  Widget _buildWorkbenchTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardWhite,
      onRefresh: () => _viewModel.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incoming Call Request Card (Pink) when incoming call arrives
            if (_viewModel.hasIncomingCall) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD1E3), // Soft pink
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Tags Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D6D), // Bright red
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.call_received_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'INCOMING CALL REQUEST',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.4,
                            ),
                          ),
                          child: Text(
                            'Rate: ${_viewModel.selectedRate} Coins/sec',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Caller Header: Avatar, Name, Category
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB7D5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.8,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.strokeBlack,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _viewModel.callerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _viewModel.callTopic,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5A189A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons: Accept / Decline
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isAcceptingCall
                                ? null
                                : () async {
                                    setState(() {
                                      _isAcceptingCall = true;
                                    });
                                    try {
                                      final callModel = await _viewModel
                                          .acceptCall();
                                      if (callModel != null && mounted) {
                                        await AudioCallScreen.start(
                                          context,
                                          callModel,
                                        );
                                        if (mounted) {
                                          _viewModel.refresh();
                                        }
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isAcceptingCall = false;
                                        });
                                      }
                                    }
                                  },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF06D6A0), // Bright green
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.strokeBlack,
                                  width: 1.8,
                                ),
                                boxShadow: AppTheme.neoShadow(
                                  offset: const Offset(2.5, 2.5),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: _isAcceptingCall
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.strokeBlack,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Connecting...',
                                          style: TextStyle(
                                            color: AppColors.textBlack,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.call_rounded,
                                          color: AppColors.strokeBlack,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Accept Call',
                                          style: TextStyle(
                                            color: AppColors.textBlack,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _viewModel.declineCall(),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF476F),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 1.8,
                              ),
                              boxShadow: AppTheme.neoShadow(
                                offset: const Offset(2, 2),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Reject',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
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
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 4),

            // Recent Sessions Section
            const Text(
              'Recent Handled Calls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 12),

            // Session Cards
            if (_viewModel.handledSessions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(
                      Icons.history_toggle_off_rounded,
                      size: 36,
                      color: AppColors.textBlack,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No Call Sessions Yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep your DUTY ON to receive incoming calls from users!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
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
                itemCount: _viewModel.handledSessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = _viewModel.handledSessions[index];
                  return _buildHandledSessionCard(session);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandledSessionCard(HandledSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.strokeBlack, width: 2.0),
        boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFAEC4FE),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeBlack, width: 1.6),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.strokeBlack,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Name and call details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.clientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.callType} • ${session.duration}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A4E69),
                  ),
                ),
              ],
            ),
          ),

          // Earned coins & timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${session.coinsEarned} 🪙',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                session.timeAgo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7E849E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // TAB 2: Agent Profile / Form Configuration
  Widget _buildAgentFormTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardWhite,
      onRefresh: () => _viewModel.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GABBY TALK AGENT PROFILE Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentLavender,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.strokeBlack,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'GABBY TALK AGENT PROFILE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Title & Subtitle
            const Text(
              'Agent Profile & Preferences',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Update your display name, service profession, spoken languages, and bio displayed to users.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // White Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AGENT DISPLAY NAME
                  const Text(
                    'AGENT DISPLAY NAME',
                    style: AppTypography.labelUppercase,
                  ),
                  const SizedBox(height: 8),
                  _buildFormField(
                    controller: _displayNameController,
                    icon: Icons.person_outline_rounded,
                    hintText: 'Display name',
                    onChanged: _viewModel.setDisplayName,
                  ),
                  const SizedBox(height: 18),

                  // SERVICE CATEGORY & PROFESSION
                  const Text(
                    'SERVICE CATEGORY & PROFESSION',
                    style: AppTypography.labelUppercase,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 2.0,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Builder(
                        builder: (context) {
                          final professions = _effectiveProfessionsList;
                          final currentValue =
                              professions.contains(
                                _viewModel.selectedProfession,
                              )
                              ? _viewModel.selectedProfession
                              : (professions.isNotEmpty
                                    ? professions.first
                                    : null);

                          return DropdownButton<String>(
                            value: currentValue,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.strokeBlack,
                            ),
                            items: professions.map((String p) {
                              return DropdownMenuItem<String>(
                                value: p,
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.textBlack,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? val) {
                              if (val != null) _viewModel.setProfession(val);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // LANGUAGES SPOKEN
                  const Text(
                    'LANGUAGES SPOKEN',
                    style: AppTypography.labelUppercase,
                  ),
                  const SizedBox(height: 8),
                  _buildFormField(
                    controller: _languagesController,
                    icon: Icons.language_rounded,
                    hintText: 'e.g. English, Hindi, Spanish',
                    onChanged: _viewModel.setLanguages,
                  ),
                  const SizedBox(height: 18),

                  // AGENT BIO & SERVICE DESCRIPTION
                  const Text(
                    'AGENT BIO & SERVICE DESCRIPTION',
                    style: AppTypography.labelUppercase,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 2.0,
                      ),
                    ),
                    child: TextField(
                      controller: _bioController,
                      maxLines: 4,
                      onChanged: _viewModel.setBio,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textBlack,
                        height: 1.35,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter your bio...',
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Profile Changes Button
                  GestureDetector(
                    onTap: () async {
                      await _viewModel.submitDutyForm();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile Changes Saved! ✨'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.strokeBlack,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.0,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(3, 3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _viewModel.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Profile Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Actions / Logout Section Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT ACTIONS',
                    style: AppTypography.labelUppercase,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(
                              color: AppColors.strokeBlack,
                              width: 2.2,
                            ),
                          ),
                          title: const Text(
                            'Log Out?',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          content: const Text(
                            'Are you sure you want to log out of your Gabby Talk Agent account?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textBlack,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _onLogout();
                              },
                              child: const Text(
                                'Log Out',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFD1E3,
                        ), // Soft pink Neo Brutalist
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.0,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(2.5, 2.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: AppColors.strokeBlack,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Log Out of Agent Account',
                            style: TextStyle(
                              fontSize: 14,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.strokeBlack, width: 2.0),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.textBlack,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Icon(icon, color: AppColors.strokeBlack, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // TAB 1: Agent Earnings Ledger
  Widget _buildEarningsTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardWhite,
      onRefresh: () => _viewModel.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AGENT EARNINGS LEDGER Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCE8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wallet_rounded,
                    size: 14,
                    color: AppColors.strokeBlack,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'AGENT EARNINGS LEDGER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Total Coin Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCE8), // Warm cream
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL COIN BALANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_viewModel.totalCoinBalance}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlack,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🏛️', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (_viewModel.totalCoinBalance < 5000) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Minimum 5,000 coins required to request payout (Current: ${_viewModel.totalCoinBalance} 🪙)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF1E1E24),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          final success = await _viewModel.requestPayout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Payout request for ${_viewModel.totalCoinBalance} coins submitted! 💰'
                                      : 'Failed to submit payout request. Please try again.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                backgroundColor: success
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFEF476F),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        child: Opacity(
                          opacity: _viewModel.totalCoinBalance >= 5000 ? 1.0 : 0.75,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.strokeBlack,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 1.5,
                              ),
                              boxShadow: _viewModel.totalCoinBalance >= 5000
                                  ? AppTheme.neoShadow(
                                      offset: const Offset(2, 2),
                                    )
                                  : null,
                            ),
                            child: const Text(
                              'Request Payout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Estimated Value: ~\$${(_viewModel.totalCoinBalance / 100).toStringAsFixed(2)} USD • Payouts processed weekly',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlack.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Earnings History Section
            const Text(
              'Earnings History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 12),

            // Earnings Ledger Card or Empty State
            if (_viewModel.earningsHistory.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 38,
                      color: AppColors.textBlack,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Earnings Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete calls with users to start earning coins and see your payout history here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _viewModel.earningsHistory.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    thickness: 1.2,
                    color: Color(0xFFE2E4EB),
                  ),
                  itemBuilder: (context, index) {
                    final entry = _viewModel.earningsHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                entry.timestamp,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7E849E),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '+${entry.coins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF06D6A0), // Bright green
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('🪙', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Floating Bottom Navigation Bar (3 items)
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
          _buildNavItem(
            index: 0,
            icon: Icons.headset_mic_rounded,
            label: 'Workbench',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.account_balance_wallet_rounded,
            label: 'Earnings',
          ),
          _buildNavItem(index: 2, icon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _viewModel.activeTab == index;

    return GestureDetector(
      onTap: () => _viewModel.setTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLavender : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: AppColors.strokeBlack, width: 1.8)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.strokeBlack),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
