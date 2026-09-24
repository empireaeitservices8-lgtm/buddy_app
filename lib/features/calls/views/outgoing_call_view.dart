import 'package:flutter/material.dart';
import '../models/call_session_model.dart';
import '../viewmodels/call_viewmodel.dart';

class OutgoingCallView extends StatefulWidget {
  final String callerName;
  final String callerSubtitle;
  final String rating;
  final String? avatarUrl;
  final bool isPro;
  final CallViewModel? viewModel;
  final VoidCallback? onEndCall;

  const OutgoingCallView({
    super.key,
    this.callerName = 'Tester',
    this.callerSubtitle = 'Friendly Chat · Emotional Support',
    this.rating = '5.0',
    this.avatarUrl,
    this.isPro = true,
    this.viewModel,
    this.onEndCall,
  });

  @override
  State<OutgoingCallView> createState() => _OutgoingCallViewState();
}

class _OutgoingCallViewState extends State<OutgoingCallView>
    with SingleTickerProviderStateMixin {
  late bool _isMuted;
  late bool _isSpeakerOn;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.viewModel?.isMuted ?? false;
    _isSpeakerOn = widget.viewModel?.isSpeakerOn ?? false;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 155.0, end: 185.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.viewModel?.addListener(_onViewModelUpdated);
  }

  void _onViewModelUpdated() {
    if (mounted) {
      setState(() {
        _isMuted = widget.viewModel?.isMuted ?? _isMuted;
        _isSpeakerOn = widget.viewModel?.isSpeakerOn ?? _isSpeakerOn;
      });
      if (widget.viewModel?.session.status == CallStatus.ended ||
          widget.viewModel?.session.status == CallStatus.rejected) {
        if (widget.onEndCall != null) {
          widget.onEndCall!();
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

  void _toggleMute() {
    if (widget.viewModel != null) {
      widget.viewModel!.toggleMute();
    } else {
      setState(() => _isMuted = !_isMuted);
    }
  }

  void _toggleSpeaker() {
    if (widget.viewModel != null) {
      widget.viewModel!.toggleSpeaker();
    } else {
      setState(() => _isSpeakerOn = !_isSpeakerOn);
    }
  }

  void _handleEndCall() {
    if (widget.viewModel != null) {
      widget.viewModel!.endCall();
    }
    if (widget.onEndCall != null) {
      widget.onEndCall!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBadgeText = widget.viewModel != null
        ? (widget.viewModel!.isConnected
            ? widget.viewModel!.formattedDuration
            : widget.viewModel!.statusText)
        : 'CALLING...';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3), // Soft Cream Canvas
      body: SafeArea(
        child: Stack(
          children: [
            // Background Pastel Circles / Blobs
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4F19C), // Pastel Lime
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFE2C6), // Soft Beige Blob
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main Content Layer
            Column(
              children: [
                const SizedBox(height: 16),
                // Header: Logo + Status Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
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
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF1E2022), width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF1E2022),
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
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
                ),

                const Spacer(),

                // Center Large Avatar with Pulse Rings
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
                              color: const Color(0xFFE8EBFD).withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Middle Ring
                          Container(
                            width: 155,
                            height: 155,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EBFD).withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Main Cartoon Neubrutal Avatar
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EBFD), // Soft Lavender Fill
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF1E2022), width: 3.5),
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
                                        width: 124,
                                        height: 124,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildAvatarInitial(),
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

                // Caller Name & Verified Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.callerName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E2022),
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle,
                        color: Color(0xFF38BDF8), size: 22),
                    if (widget.isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3C4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF1E2022), width: 1.8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF1E2022),
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
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
                  ],
                ),

                const SizedBox(height: 8),

                // Subtitle Tag
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    widget.callerSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Star Rating Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C4), // Light Yellow
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF1E2022), width: 2),
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
                      const Icon(Icons.star_rounded,
                          size: 18, color: Color(0xFF1E2022)),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Call Control Action Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Button
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isMuted
                                ? const Color(0xFFFFD1DC)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF1E2022), width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF1E2022),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: const Color(0xFF1E2022),
                            size: 26,
                          ),
                        ),
                      ),

                      // End Call Button (Red Neubrutal)
                      GestureDetector(
                        onTap: _handleEndCall,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252), // Red Accent
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF1E2022), width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF1E2022),
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white, size: 34),
                        ),
                      ),

                      // Speaker Button
                      GestureDetector(
                        onTap: _toggleSpeaker,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isSpeakerOn
                                ? const Color(0xFFD4F19C)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF1E2022), width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF1E2022),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isSpeakerOn
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarInitial() {
    return Text(
      widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : 'T',
      style: const TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E2022),
      ),
    );
  }
}
