// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/agora_service.dart';
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

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    if (widget.viewModel.activeCallMatch != null && !widget.viewModel.isCallAttended) {
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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF1B1B1E), // Dark neo-black sheet
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle indicator
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Animated Avatar with Ringing Pulse Rings
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse rings when ringing or active talking
                      AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          final ringColor1 = isAttended
                              ? const Color(0xFF06D6A0)
                              : const Color(0xFFD6F887);
                          final ringColor2 = isAttended
                              ? const Color(0xFF06D6A0).withOpacity(0.4)
                              : const Color(0xFFB8C4FE);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 90 + (32 * _rippleController.value),
                                height: 90 + (32 * _rippleController.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ringColor1.withOpacity(
                                    (1.0 - _rippleController.value) * (isAttended ? 0.3 : 0.4),
                                  ),
                                ),
                              ),
                              Container(
                                width: 90 + (18 * _rippleController.value),
                                height: 90 + (18 * _rippleController.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ringColor2.withOpacity(
                                    (1.0 - _rippleController.value) * (isAttended ? 0.4 : 0.5),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Gender Image Circle (No DP)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: match.isFemale
                              ? const Color(0xFFFFF0F5)
                              : const Color(0xFFF0F9FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAttended
                                ? const Color(0xFF06D6A0)
                                : AppColors.strokeBlack,
                            width: 3.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isAttended
                                  ? const Color(0xFF06D6A0).withOpacity(0.3)
                                  : Colors.black26,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            match.genderImageAsset,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Call Title (Ringing vs Active)
                Text(
                  isAttended
                      ? 'Call with ${match.name}'
                      : 'Calling ${match.name}...',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Profession / Waiting Subtitle
                Text(
                  isAttended
                      ? match.profession
                      : 'Waiting for ${match.name} to attend...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAttended
                        ? const Color(0xFFD6F887)
                        : Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Live Status Badge
                if (!isAttended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD166).withOpacity(0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔔 ', style: TextStyle(fontSize: 13)),
                        Text(
                          'Ringing...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD166),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  StreamBuilder<AgoraCallState>(
                    stream: widget.viewModel.agoraService.callStateStream,
                    initialData: widget.viewModel.agoraService.callState,
                    builder: (context, snapshot) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06D6A0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF06D6A0).withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🟢 ', style: TextStyle(fontSize: 11)),
                            Text(
                              'HD Voice Call • Connected',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF06D6A0),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 18),

                // Info / Timer & Coin Deducting Card
                if (!isAttended)
                  // Ringing notice card (0 coins spent during ringing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28292E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('✨ ', style: TextStyle(fontSize: 14)),
                            Text(
                              'Ringing (Free)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        () {
                          final effectiveRate =
                              (match.rateCoinsPerSec <= 0 || match.rateCoinsPerSec == 3)
                                  ? 5
                                  : match.rateCoinsPerSec;
                          return Text(
                            'Rate: $effectiveRate Coins/sec • Coins charged only after call connects\nWallet Balance: ${widget.viewModel.walletCoins} 🪙',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          );
                        }(),
                      ],
                    ),
                  )
                else
                  // Connected live duration & coin deduction card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28292E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.viewModel.isLowCoinWarning
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF06D6A0).withOpacity(0.3),
                        width: widget.viewModel.isLowCoinWarning ? 2.0 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.viewModel.isLowCoinWarning ? '⚠️ ' : '⏱️ ',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '${widget.viewModel.formattedCallDuration} • -${widget.viewModel.callCoinsSpent} Coins',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: widget.viewModel.isLowCoinWarning
                                    ? const Color(0xFFFF8A80)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        () {
                          final effectiveRate =
                              (match.rateCoinsPerSec <= 0 || match.rateCoinsPerSec == 3)
                                  ? 5
                                  : match.rateCoinsPerSec;
                          return Text(
                            widget.viewModel.isLowCoinWarning
                                ? '⚠️ Low Balance (${widget.viewModel.walletCoins} Coins)! Rate: $effectiveRate Coins/sec'
                                : 'Rate: $effectiveRate Coins/sec • Wallet Balance: ${widget.viewModel.walletCoins} 🪙',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: widget.viewModel.isLowCoinWarning
                                  ? const Color(0xFFFF8A80)
                                  : Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }(),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),

                // Call Controls: Mute, Hang Up, Speaker
                Row(
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
                              ? Colors.white24
                              : const Color(0xFF33343A),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.viewModel.isMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),

                    // End / Cancel Call Button (Large Red Button)
                    GestureDetector(
                      onTap: () {
                        widget.viewModel.endCall();
                        Navigator.of(context).maybePop();
                      },
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4B4B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4B4B).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
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

                    // Speaker Button
                    GestureDetector(
                      onTap: widget.viewModel.toggleSpeaker,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: widget.viewModel.isSpeakerOn
                              ? const Color(0xFF33343A)
                              : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.viewModel.isSpeakerOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
