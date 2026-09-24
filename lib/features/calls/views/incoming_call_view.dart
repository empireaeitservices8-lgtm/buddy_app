import 'package:flutter/material.dart';
import '../models/call_session_model.dart';
import '../viewmodels/call_viewmodel.dart';

class IncomingCallView extends StatefulWidget {
  final String callerName;
  final String callerSubtitle;
  final String rating;
  final String? avatarUrl;
  final bool isPro;
  final CallViewModel? viewModel;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const IncomingCallView({
    super.key,
    this.callerName = 'Maya R.',
    this.callerSubtitle = 'wants to talk with you',
    this.rating = '5.0',
    this.avatarUrl,
    this.isPro = false,
    this.viewModel,
    this.onAccept,
    this.onReject,
  });

  @override
  State<IncomingCallView> createState() => _IncomingCallViewState();
}

class _IncomingCallViewState extends State<IncomingCallView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 155.0, end: 185.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.viewModel?.addListener(_onViewModelUpdated);
  }

  void _onViewModelUpdated() {
    if (mounted) {
      setState(() {});
      if (widget.viewModel?.session.status == CallStatus.ended ||
          widget.viewModel?.session.status == CallStatus.rejected) {
        if (widget.onReject != null) {
          widget.onReject!();
        } else {
          Navigator.maybePop(context);
        }
      }
    }
  }

  @override
  void dispose() {
    widget.viewModel?.removeListener(_onViewModelUpdated);
    _pulseController.dispose();
    super.dispose();
  }

  void _handleAccept() {
    if (widget.viewModel != null) {
      widget.viewModel!.acceptCall();
    }
    if (widget.onAccept != null) {
      widget.onAccept!();
    }
  }

  void _handleReject() {
    if (widget.viewModel != null) {
      widget.viewModel!.rejectCall();
    }
    if (widget.onReject != null) {
      widget.onReject!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3), // Soft Cream Canvas
      body: SafeArea(
        child: Stack(
          children: [
            // Top-Right Pastel Lime Blob
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 270,
                height: 270,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4F19C), // Pastel Lime
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Middle-Left Soft Beige/Grey Blob
            Positioned(
              top: 100,
              left: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5DFD3), // Soft Beige/Grey
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Bottom-Left Pastel Greenish Blob
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F19C).withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main Content Layer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Header Bar: Logo + Status Badge
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
                                color: Color(0xFFFF8A9A), // Pink Accent
                                fontFamily: 'Inter',
                              ),
                            ),
                            TextSpan(
                              text: 'Talk',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00C4B4), // Teal Accent
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F19C),
                          borderRadius: BorderRadius.circular(20),
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
                        child: const Text(
                          'INCOMING CALL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E2022),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Center Large Avatar with Concentric Pulse Rings
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Concentric Pulse Ring
                            Container(
                              width: _pulseAnimation.value,
                              height: _pulseAnimation.value,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EBFD)
                                    .withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Middle Ring
                            Container(
                              width: 155,
                              height: 155,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EBFD)
                                    .withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Main Cartoon Neubrutal Avatar
                            Container(
                              width: 135,
                              height: 135,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EBFD), // Soft Lavender Fill
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
                              child: Center(
                                child: widget.avatarUrl != null &&
                                        widget.avatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.avatarUrl!,
                                          width: 128,
                                          height: 128,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildAvatarInitial(),
                                        ),
                                      )
                                    : _buildAvatarInitial(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Caller Name
                  Text(
                    widget.callerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E2022),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle Tag: "wants to talk with you"
                  Text(
                    widget.callerSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Ringing with Cyan Animated Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Ringing',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C4B4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C4B4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C4B4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom Action Buttons: Decline (Red) & Accept (Green)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Decline Button (Red Neubrutal)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _handleReject,
                              child: Container(
                                width: 76,
                                height: 76,
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
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Decline',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E2022),
                              ),
                            ),
                          ],
                        ),

                        // Accept Button (Green Neubrutal)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _handleAccept,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ADE80), // Vibrant Green
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
                                  Icons.call_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarInitial() {
    return Text(
      widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : 'M',
      style: const TextStyle(
        fontSize: 54,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E2022),
      ),
    );
  }
}
