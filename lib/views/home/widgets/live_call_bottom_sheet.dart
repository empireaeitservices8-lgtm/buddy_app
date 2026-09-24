// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
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
          // If call ended, close modal
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
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
                      final ringSize = avatarSize * 1.15;
                      final pulseSize = _pulseAnimation.value.clamp(avatarSize * 1.15, avatarSize * 1.37);

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
                                                  text: 'Gabby ',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFFFF8A9A),
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'Talk',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF00C4B4),
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

                                  // Center Avatar Section with Concentric Pulse Rings
                                  Center(
                                    child: AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Outer Pulse Ring
                                            Container(
                                              width: pulseSize,
                                              height: pulseSize,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8EBFD)
                                                    .withValues(alpha: 0.45),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            // Middle Ring
                                            Container(
                                              width: ringSize,
                                              height: ringSize,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8EBFD)
                                                    .withValues(alpha: 0.65),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            // Main Cartoon Neubrutal Avatar
                                            Container(
                                              width: avatarSize,
                                              height: avatarSize,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8EBFD),
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
                                              child: Text(
                                                initialLetter,
                                                style: TextStyle(
                                                  fontSize: avatarSize * 0.4,
                                                  fontWeight: FontWeight.w900,
                                                  color: const Color(0xFF1E2022),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
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
                                        Text(
                                          widget.viewModel.formattedCallDuration,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF00C4B4),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Control Buttons: Mute, End Call, Speaker
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Mute Button
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

                                        // End Call Button (Red Neubrutal)
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

                                        // Speaker Button
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
                                                  : Icons.volume_down_rounded,
                                              color: const Color(0xFF1E2022),
                                              size: 26,
                                            ),
                                          ),
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
