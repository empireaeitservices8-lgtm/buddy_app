// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../data/models/user_profile.dart';
import '../../../viewmodels/home_view_model.dart';

class LiveCallBottomSheet extends StatefulWidget {
  final HomeViewModel viewModel;

  const LiveCallBottomSheet({super.key, required this.viewModel});

  static Future<void> show(BuildContext context, HomeViewModel viewModel) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LiveCallBottomSheet(viewModel: viewModel),
    );
  }

  @override
  State<LiveCallBottomSheet> createState() => _LiveCallBottomSheetState();
}

class _LiveCallBottomSheetState extends State<LiveCallBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 155.0, end: 185.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    if (widget.viewModel.activeCallMatch != null &&
        !widget.viewModel.isCallAttended) {
      widget.viewModel.endCall();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final match = widget.viewModel.activeCallMatch;
        if (match == null) {
          if (!_hasPopped) {
            _hasPopped = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
          return const SizedBox.shrink();
        }

        final isAttended = widget.viewModel.isCallAttended;
        final initialLetter =
            match.name.isNotEmpty ? match.name[0].toUpperCase() : 'T';

        final statusBadgeText = isAttended ? 'ON CALL' : 'CALLING...';

        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFFF9F8F3), // Soft Cream Canvas
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1E2022),
                offset: Offset(0, -4),
                blurRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: Stack(
              children: [
                // Top-Right Pastel Lime Blob
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4F19C), // Pastel Lime
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Middle-Left Soft Beige Blob
                Positioned(
                  bottom: 120,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFE2C6), // Soft Beige
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final avatarSize = (constraints.maxHeight * 0.17).clamp(75.0, 135.0);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      const SizedBox(height: 12),
                                      // Drag Handle
                                      Center(
                                        child: Container(
                                          width: 44,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E2022).withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Header Bar: Gabby Talk Logo + ON CALL Badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          RichText(
                                            text: const TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Gaby ',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF0A2E65),
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'Talk',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF00A79D),
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFF1E2022),
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              statusBadgeText,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1E2022),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Dual Avatar Section: User (You) <---> Agent
                                  Builder(
                                    builder: (context) {
                                      final userProfile = widget.viewModel.userProfile;
                                      final userIsFemale = userProfile?.gender == null ||
                                          userProfile!.gender == Gender.woman;
                                      final userAvatarAsset = userIsFemale
                                          ? 'assets/images/Girl2.png'
                                          : 'assets/images/Boy2.png';
                                      final userInitial = (userProfile?.firstName.isNotEmpty == true
                                              ? userProfile!.firstName[0]
                                              : 'Y')
                                          .toUpperCase();
                                      final userBgColor = userIsFemale
                                          ? const Color(0xFFFFF0F5)
                                          : const Color(0xFFEFF6FF);
                                      final agentBgColor = match.isFemale
                                          ? const Color(0xFFFFF0F5)
                                          : const Color(0xFFEFF6FF);
                                      final smallSize = (avatarSize * 0.72).clamp(54.0, 95.0);

                                      return AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // User (You) Avatar - left
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: smallSize,
                                                    height: smallSize,
                                                    decoration: BoxDecoration(
                                                      color: userBgColor,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: const Color(0xFF1E2022),
                                                        width: 2.5,
                                                      ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Color(0xFF1E2022),
                                                          offset: Offset(0, 3),
                                                          blurRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: ClipOval(
                                                      child: Image.asset(
                                                        userAvatarAsset,
                                                        width: smallSize,
                                                        height: smallSize,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => Text(
                                                          userInitial,
                                                          style: TextStyle(
                                                            fontSize: smallSize * 0.4,
                                                            fontWeight: FontWeight.w900,
                                                            color: const Color(0xFF1E2022),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const Text(
                                                    'You',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Middle: Animated pulse wave / call indicator
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 20.0),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: List.generate(3, (i) {
                                                    final scale = (i == 1)
                                                        ? (_pulseAnimation.value - 155) / 30
                                                        : ((i == 0)
                                                              ? (_pulseAnimation.value - 155) / 50
                                                              : (_pulseAnimation.value - 155) / 20);
                                                    final opacity = (0.3 + scale.clamp(0.0, 1.0) * 0.7).clamp(0.3, 1.0);
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                                      child: Container(
                                                        width: 4,
                                                        height: 14 + (scale * 12).clamp(0.0, 12.0),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF00A79D).withValues(alpha: opacity),
                                                          borderRadius: BorderRadius.circular(3),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),

                                              // Agent Avatar - right (larger, main focus)
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: avatarSize,
                                                    height: avatarSize,
                                                    decoration: BoxDecoration(
                                                      color: agentBgColor,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: const Color(0xFF1E2022),
                                                        width: 3.5,
                                                      ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Color(0xFF1E2022),
                                                          offset: Offset(0, 4),
                                                          blurRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: ClipOval(
                                                      child: Image.asset(
                                                        match.genderImageAsset,
                                                        width: avatarSize,
                                                        height: avatarSize,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => Text(
                                                          initialLetter,
                                                          style: TextStyle(
                                                            fontSize: avatarSize * 0.4,
                                                            fontWeight: FontWeight.w900,
                                                            color: const Color(0xFF1E2022),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const Text(
                                                    'Agent',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  // Caller / Agent Name & Badges
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              match.name,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1E2022),
                                                letterSpacing: -0.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF38BDF8),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF1E2022),
                                                width: 1.8,
                                              ),
                                            ),
                                            child: const Text(
                                              'PRO',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1E2022),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Subtitle Tag
                                      Text(
                                        match.profession.isNotEmpty
                                            ? match.profession
                                            : 'Friendly Chat · Emotional Support',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Rating Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3C4), // Light Yellow
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF1E2022),
                                            width: 2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0xFF1E2022),
                                              offset: Offset(2, 2),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 18,
                                              color: Color(0xFF1E2022),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              match.rating > 0
                                                  ? match.rating.toStringAsFixed(1)
                                                  : '5.0',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1E2022),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (isAttended) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              widget.viewModel.formattedCallDuration,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF00A79D),
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: widget.viewModel.walletCoins <= 300
                                                    ? const Color(0xFFFFE5E5)
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: widget.viewModel.walletCoins <= 300
                                                      ? const Color(0xFFE11D48)
                                                      : const Color(0xFF1E2022),
                                                  width: 1.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text('🪙', style: TextStyle(fontSize: 11)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${widget.viewModel.walletCoins}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w900,
                                                      color: widget.viewModel.walletCoins <= 300
                                                          ? const Color(0xFFE11D48)
                                                          : const Color(0xFF1E2022),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (widget.viewModel.walletCoins <= 300) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF1F2),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFE11D48),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              '⚠️ Low balance: ${widget.viewModel.walletCoins} coins left',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFE11D48),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Control Buttons: Mute, End Call, Speaker / Earpiece
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Mute Button
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: widget.viewModel.toggleMute,
                                              child: Container(
                                                width: 58,
                                                height: 58,
                                                decoration: BoxDecoration(
                                                  color: widget.viewModel.isMuted
                                                      ? const Color(0xFFFFD1DC)
                                                      : Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF1E2022),
                                                    width: 2.5,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0xFF1E2022),
                                                      offset: Offset(2, 2),
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  widget.viewModel.isMuted
                                                      ? Icons.mic_off_rounded
                                                      : Icons.mic_rounded,
                                                  color: const Color(0xFF1E2022),
                                                  size: 26,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              widget.viewModel.isMuted ? 'Muted' : 'Mute',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E2022),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // End Call Button (Red Neubrutal)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                widget.viewModel.endCall();
                                                Navigator.of(context).maybePop();
                                              },
                                              child: Container(
                                                width: 72,
                                                height: 72,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF5252), // Red Accent
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF1E2022),
                                                    width: 3.2,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0xFF1E2022),
                                                      offset: Offset(3.5, 3.5),
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.call_end_rounded,
                                                  color: Colors.white,
                                                  size: 34,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'End',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E2022),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Speaker / Earpiece Button
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: widget.viewModel.toggleSpeaker,
                                              child: Container(
                                                width: 58,
                                                height: 58,
                                                decoration: BoxDecoration(
                                                  color: widget.viewModel.isSpeakerOn
                                                      ? const Color(0xFFD4F19C)
                                                      : Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF1E2022),
                                                    width: 2.5,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0xFF1E2022),
                                                      offset: Offset(2, 2),
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  widget.viewModel.isSpeakerOn
                                                      ? Icons.volume_up_rounded
                                                      : Icons.hearing_rounded,
                                                  color: const Color(0xFF1E2022),
                                                  size: 26,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              widget.viewModel.isSpeakerOn ? 'Speaker' : 'Earpiece',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E2022),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
