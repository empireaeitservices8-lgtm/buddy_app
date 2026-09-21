import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/agent_rating_model.dart';
import '../../viewmodels/agent_dashboard_view_model.dart';

/// Screen displaying the Agent's Profile, Rating breakdown, and Caller Reviews
class AgentProfileScreen extends StatefulWidget {
  final AgentDashboardViewModel viewModel;

  const AgentProfileScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  AgentDashboardViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchAgentRating();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient soft glow circles
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E7FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 280,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardWhite,
                  onRefresh: () async {
                    await Future.wait([
                      _viewModel.fetchAgentProfile(),
                      _viewModel.fetchAgentRating(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Bar
                        _buildTopBar(context),
                        const SizedBox(height: 16),

                        // 2. Profile Main Card
                        _buildProfileHeroCard(),
                        const SizedBox(height: 18),

                        // 3. Rating & Breakdown Hero Card
                        _buildRatingHeroCard(),
                        const SizedBox(height: 18),

                        // 4. Performance Stats Row
                        _buildPerformanceStatsRow(),
                        const SizedBox(height: 22),

                        // 5. Recent Caller Reviews List
                        _buildReviewsSectionHeader(),
                        const SizedBox(height: 12),
                        _buildReviewsList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Top Bar with Back Button, Title, and Refresh Button
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeBlack, width: 2),
              boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.strokeBlack,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.strokeBlack, width: 2),
            boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_pin_rounded,
                size: 18,
                color: AppColors.strokeBlack,
              ),
              SizedBox(width: 6),
              Text(
                'AGENT PROFILE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            _viewModel.fetchAgentProfile();
            _viewModel.fetchAgentRating();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeBlack, width: 2),
              boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
            ),
            child: _viewModel.isLoadingRating
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.strokeBlack),
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.strokeBlack,
                  ),
          ),
        ),
      ],
    );
  }

  // Profile Hero Card (Avatar, Name, Profession, Rate, Bio, Interests)
  Widget _buildProfileHeroCard() {
    final profile = _viewModel.agentProfile;
    final pic = _viewModel.profilePicture;
    final hasValidPic = pic != null && pic.isNotEmpty && pic.startsWith('http');

    return Container(
      width: double.infinity,
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
          // Row: Avatar, Name, Verified, PRO badge
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCE8),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.strokeBlack, width: 2),
                    ),
                    child: ClipOval(
                      child: hasValidPic
                          ? Image.network(
                              pic,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.headset_mic_rounded,
                                size: 34,
                                color: AppColors.strokeBlack,
                              ),
                            )
                          : const Icon(
                              Icons.headset_mic_rounded,
                              size: 34,
                              color: AppColors.strokeBlack,
                            ),
                    ),
                  ),
                  // Online/Duty Indicator
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _viewModel.isDutyOn
                            ? const Color(0xFF22C55E)
                            : AppColors.errorRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardWhite, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _viewModel.agentName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlack,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLavender,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.4,
                            ),
                          ),
                          child: const Text(
                            'AGENT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Profession
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.strokeBlack.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        _viewModel.profession,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack.withOpacity(0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Rate Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.strokeBlack, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🪙 ',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                '${_viewModel.selectedRate} coins/sec',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (profile?.agentId != null)
                          Text(
                            'ID: #${profile!.agentId}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bio
          if (_viewModel.bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.strokeBlack.withOpacity(0.2), width: 1.2),
              ),
              child: Text(
                '"${_viewModel.bio}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],

          // Interests Tags
          if (_viewModel.interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _viewModel.interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLavenderLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.strokeBlack, width: 1.2),
                  ),
                  child: Text(
                    '#$interest',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textBlack,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Rating Hero Card with Star Breakdown
  Widget _buildRatingHeroCard() {
    final ratingData = _viewModel.ratingData;
    final avgRating = ratingData?.averageRating ?? _viewModel.rating;
    final totalReviews = ratingData?.totalReviews ?? (ratingData?.recentReviews.length ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentLavender,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.strokeBlack, width: 2.2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 20,
                    color: AppColors.strokeBlack,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'RATING & REVIEWS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppColors.textBlack,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.strokeBlack, width: 1.4),
                ),
                child: Text(
                  totalReviews == 1 ? '1 Review' : '$totalReviews Reviews',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating Overview Row: Score on left + 5-Star Breakdown Bars on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Big Average Rating Score
              Container(
                width: 105,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.strokeBlack, width: 2),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starThreshold = index + 1;
                        final isFull = avgRating >= starThreshold;
                        final isHalf = !isFull && avgRating >= (starThreshold - 0.5);

                        return Icon(
                          isFull
                              ? Icons.star_rounded
                              : (isHalf ? Icons.star_half_rounded : Icons.star_outline_rounded),
                          size: 16,
                          color: const Color(0xFFFFB800),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Out of 5.0',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Right Column: Star Breakdown Bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final percentage = ratingData?.percentageForStar(star) ?? (star == 5 ? 1.0 : 0.0);
                    final count = ratingData?.ratingBreakdown[star] ?? (star == 5 && totalReviews > 0 ? totalReviews : 0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Text(
                            '$star★',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.strokeBlack.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB800),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Performance Stats Row (Calls, Earnings, Duty)
  Widget _buildPerformanceStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatMiniCard(
            title: 'TOTAL CALLS',
            value: '${_viewModel.totalCalls}',
            icon: Icons.call_rounded,
            badgeColor: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMiniCard(
            title: 'EARNED TODAY',
            value: '${_viewModel.todayEarned} 🪙',
            icon: Icons.monetization_on_rounded,
            badgeColor: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMiniCard(
            title: 'DUTY TIME',
            value: _viewModel.dutyTime,
            icon: Icons.timer_rounded,
            badgeColor: const Color(0xFFFFE4E6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.strokeBlack, width: 2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeBlack, width: 1.2),
            ),
            child: Icon(icon, size: 14, color: AppColors.strokeBlack),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: AppColors.textSecondary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Section Header for Reviews
  Widget _buildReviewsSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(
              Icons.forum_rounded,
              size: 20,
              color: AppColors.strokeBlack,
            ),
            SizedBox(width: 8),
            Text(
              'CALLER FEEDBACK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: AppColors.textBlack,
              ),
            ),
          ],
        ),
        if (_viewModel.isLoadingRating)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.strokeBlack),
            ),
          ),
      ],
    );
  }

  // Reviews List
  Widget _buildReviewsList() {
    final reviews = _viewModel.ratingData?.recentReviews ?? [];

    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.strokeBlack, width: 2),
          boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.reviews_rounded,
                size: 30,
                color: AppColors.strokeBlack,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Caller Reviews Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Accept and complete voice calls to receive feedback and star ratings from callers!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withOpacity(0.85),
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: reviews.map((review) => _buildReviewCard(review)).toList(),
    );
  }

  // Single Caller Review Card
  Widget _buildReviewCard(AgentReviewItem review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.strokeBlack, width: 2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Caller Avatar, Name, Rating Pill & Date
          Row(
            children: [
              // Caller Avatar / Initial
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.strokeBlack, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    review.callerName.isNotEmpty
                        ? review.callerName.substring(0, 1).toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.strokeBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Caller Name & Call Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.callerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Rating Stars Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.strokeBlack, width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFB800),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${review.rating}.0',
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

          // Feedback Quote
          if (review.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.strokeBlack.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Text(
                '"${review.feedback}"',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textBlack,
                  height: 1.3,
                ),
              ),
            ),
          ],

          // Footer info
          if (review.callId > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Call Session #${review.callId}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
