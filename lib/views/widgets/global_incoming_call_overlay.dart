import 'package:flutter/material.dart';
import '../../core/services/incoming_call_manager.dart';

/// Global overlay widget rendered at the root of MaterialApp
/// so that agents can see and respond to incoming calls from ANY screen in the app.
class GlobalIncomingCallOverlay extends StatefulWidget {
  final Widget child;

  const GlobalIncomingCallOverlay({super.key, required this.child});

  @override
  State<GlobalIncomingCallOverlay> createState() =>
      _GlobalIncomingCallOverlayState();
}

class _GlobalIncomingCallOverlayState extends State<GlobalIncomingCallOverlay>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final IncomingCallManager _callManager;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callManager = IncomingCallManager.instance;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 155.0, end: 185.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _callManager.checkPendingCall();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _callManager,
      builder: (context, _) {
        return Stack(
          children: [
            widget.child,
            if (_callManager.hasIncomingCall)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: _buildIncomingCallScreen(context),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIncomingCallScreen(BuildContext context) {
    final callerInitial = _callManager.callerName.trim().isNotEmpty
        ? _callManager.callerName.trim()[0].toUpperCase()
        : 'C';

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
                  color: Color(0xFFE5DFD3), // Soft Beige/Grey Blob
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Bottom-Left Pastel Greenish Accent Blob
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

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Header Bar: Gabby Talk Logo + Incoming Call Badge
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

                  // Center Profile: Concentric Pulse Rings + Large Lavender Avatar
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Soft Pulse Ring
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
                                    .withValues(alpha: 0.7),
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
                              alignment: Alignment.center,
                              child: Text(
                                callerInitial,
                                style: const TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E2022),
                                ),
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
                    _callManager.callerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E2022),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle: "wants to talk with you"
                  const Text(
                    'wants to talk with you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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

                  const SizedBox(height: 14),

                  // Earning Rate / Topic Badge (Neubrutalist Pill)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3C4), // Light yellow
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1E2022),
                        width: 1.8,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1E2022),
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_callManager.callTopic} • ${_callManager.callRateText}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Actions: Decline (Red) & Accept (Green)
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
                              onTap: () async {
                                await _callManager.declineCall();
                              },
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
                              onTap: _callManager.isAccepting
                                  ? null
                                  : () async {
                                      await _callManager.acceptCall(context);
                                    },
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
                                child: _callManager.isAccepting
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(
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
}
