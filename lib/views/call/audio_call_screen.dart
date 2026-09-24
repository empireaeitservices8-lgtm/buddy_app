// ignore_for_file: use_build_context_synchronously, duplicate_ignore, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/call_model.dart';
import '../../viewmodels/call_view_model.dart';
import '../home/widgets/agent_rating_bottom_sheet.dart';

class AudioCallScreen extends StatefulWidget {
  final CallModel callModel;

  const AudioCallScreen({super.key, required this.callModel});

  static Future<void> start(BuildContext context, CallModel callModel) async {
    final callVm = CallViewModel()..startCall(callModel);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: callVm,
          child: AudioCallScreen(callModel: callModel),
        ),
      ),
    );

    // If caller is user side (outgoing call to agent) and the call was answered/connected:
    if (callModel.isOutgoing && callVm.wasConnected && context.mounted) {
      await AgentRatingBottomSheet.show(
        context,
        agentId: callModel.receiverId,
        agentName: callModel.receiverName,
        agentAvatar: callModel.receiverAvatar,
        callId: int.tryParse(callModel.callId),
      );
    }
    callVm.dispose();
  }

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 155.0, end: 185.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallViewModel>(
      builder: (context, vm, child) {
        final call = vm.callModel ?? widget.callModel;
        final targetName = call.isOutgoing
            ? (call.receiverName.isNotEmpty ? call.receiverName : 'Tester')
            : (call.callerName.isNotEmpty ? call.callerName : 'Caller');

        final initialLetter = targetName.trim().isNotEmpty
            ? targetName.trim()[0].toUpperCase()
            : 'T';

        // Auto-close on ended
        if (call.status == CallStatus.ended && !_hasPopped) {
          _hasPopped = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        final statusBadgeText = call.status == CallStatus.connected
            ? 'ON CALL'
            : (call.status == CallStatus.calling
                ? 'CALLING...'
                : (call.status == CallStatus.ringing ? 'RINGING...' : 'ON CALL'));

        return Scaffold(
          backgroundColor: const Color(0xFFF9F8F3), // Soft Cream Canvas
          body: SafeArea(
            child: Stack(
              children: [
                // Top-Right Pastel Lime Blob
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

                // Middle-Left Soft Beige Blob
                Positioned(
                  bottom: 120,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final avatarSize = (constraints.maxHeight * 0.17).clamp(80.0, 135.0);
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
                                    const SizedBox(height: 16),
                                    // Header Bar: Gabby Talk Logo + Status Badge
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
                                        // Status Pill Badge (ON CALL)
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

                                // Center Profile: Pulse Rings + Avatar
                                Center(
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outer Concentric Pulse Ring
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

                                // Caller Name & Verified Badges
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            targetName,
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
                                    const Text(
                                      'Friendly Chat · Emotional Support',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Star Rating Pill
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
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 18,
                                            color: Color(0xFF1E2022),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '5.0',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1E2022),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (call.status == CallStatus.connected) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        vm.formattedDuration,
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

                                // Bottom Action Controls: Mute, End Call, Speaker
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 32.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Mute Button
                                      GestureDetector(
                                        onTap: vm.toggleMute,
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            color: vm.isMuted
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
                                            vm.isMuted
                                                ? Icons.mic_off_rounded
                                                : Icons.mic_rounded,
                                            color: const Color(0xFF1E2022),
                                            size: 26,
                                          ),
                                        ),
                                      ),

                                      // End Call Button (Red Neubrutal)
                                      GestureDetector(
                                        onTap: () async {
                                          await vm.endCall();
                                          if (mounted && Navigator.of(context).canPop()) {
                                            Navigator.of(context).pop();
                                          }
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

                                      // Speakerphone Button
                                      GestureDetector(
                                        onTap: vm.toggleSpeaker,
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            color: vm.isSpeakerOn
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
                                            vm.isSpeakerOn
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
              ],
            ),
          ),
        );
      },
    );
  }
}
