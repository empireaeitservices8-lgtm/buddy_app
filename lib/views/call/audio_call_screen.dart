// ignore_for_file: use_build_context_synchronously, duplicate_ignore, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
            ? call.receiverName
            : call.callerName;

        // Auto-close on ended
        if (call.status == CallStatus.ended && !_hasPopped) {
          _hasPopped = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF131316),
          body: SafeArea(
            child: Stack(
              children: [
                // Background Soft Ambient Glow
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: const Color(0xFF6366F1).withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: -50,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06D6A0).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Main Call Layout
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      // Top Bar with Minimize / Secure Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white24,
                                width: 1.2,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF06D6A0),
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'End-to-End Encrypted',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const Spacer(),

                      // Animated Avatar with Pulse Rings
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final isConnected =
                              call.status == CallStatus.connected;
                          final scale = isConnected
                              ? _pulseAnimation.value
                              : 1.0;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulse ring 2
                              if (isConnected)
                                Transform.scale(
                                  scale: scale * 1.22,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFFB8C4FE,
                                        ).withOpacity(0.2),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                ),

                              // Pulse ring 1
                              if (isConnected)
                                Transform.scale(
                                  scale: scale * 1.1,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(
                                        0xFFB8C4FE,
                                      ).withOpacity(0.15),
                                    ),
                                  ),
                                ),

                              // Main Avatar Box
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.accentLavender,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.strokeBlack,
                                    width: 3.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.headset_mic_rounded,
                                  size: 60,
                                  color: AppColors.strokeBlack,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // User Name
                      Text(
                        targetName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Call Status & Duration
                      _buildStatusIndicator(call, vm),
                      const Spacer(),

                      // Remote Muted Notice
                      if (vm.isRemoteAudioMuted &&
                          call.status == CallStatus.connected)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_off,
                                size: 14,
                                color: Colors.orangeAccent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Remote participant is muted',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Control Dock: Mute, Hang Up, Speaker (Cartoon Neo-Brutalist Dock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: Colors.white24,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Mute Button
                            _buildControlButton(
                              icon: vm.isMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              label: vm.isMuted ? 'Unmute' : 'Mute',
                              isActive: vm.isMuted,
                              activeColor: const Color(0xFFFFB8D2),
                              onTap: vm.toggleMute,
                            ),

                            // End Call Button (Cartoon Red Pill with Hard Shadow)
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
                                  color: const Color(0xFFFF4D6D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      offset: const Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),

                            // Speakerphone Button
                            _buildControlButton(
                              icon: vm.isSpeakerOn
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              label: vm.isSpeakerOn ? 'Speaker' : 'Earpiece',
                              isActive: vm.isSpeakerOn,
                              activeColor: const Color(0xFFC7D2FE),
                              onTap: vm.toggleSpeaker,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(CallModel call, CallViewModel vm) {
    switch (call.status) {
      case CallStatus.calling:
        return Text(
          call.isOutgoing ? 'Calling...' : 'Connecting...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFD166),
          ),
        );
      case CallStatus.ringing:
        return Text(
          call.isOutgoing ? 'Ringing...' : 'Connecting...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFD166),
          ),
        );
      case CallStatus.connected:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF06D6A0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              vm.formattedDuration,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF06D6A0),
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      case CallStatus.reconnecting:
        return const Text(
          'Reconnecting...',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFB7D5),
          ),
        );
      case CallStatus.ended:
        return const Text(
          'Call Ended',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
          ),
        );
      case CallStatus.error:
        return Text(
          vm.errorMessage ?? 'Connection Failed',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF3366),
          ),
        );
      case CallStatus.idle:
      // ignore: unreachable_switch_default
      default:
        return const Text(
          'Connecting to Agora RTC...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
          ),
        );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? activeColor : const Color(0xFF2E2F35),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppColors.strokeBlack : Colors.white12,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.strokeBlack : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
