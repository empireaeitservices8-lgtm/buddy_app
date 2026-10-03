// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/home_view_model.dart';
import '../../widgets/toast_utils.dart';
import '../coins_store_screen.dart';
import 'dummy_payment_gateway_sheet.dart';

class ZeroCoinsBottomSheet extends StatefulWidget {
  final HomeViewModel viewModel;
  final String? title;
  final String? message;

  const ZeroCoinsBottomSheet({
    super.key,
    required this.viewModel,
    this.title,
    this.message,
  });

  static bool _isShowing = false;

  static Future<void> show(
    BuildContext context,
    HomeViewModel viewModel, {
    String? title,
    String? message,
  }) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (ctx) => ZeroCoinsBottomSheet(
          viewModel: viewModel,
          title: title,
          message: message,
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<ZeroCoinsBottomSheet> createState() => _ZeroCoinsBottomSheetState();
}

class _ZeroCoinsBottomSheetState extends State<ZeroCoinsBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  final List<CoinBundle> _bundles = const [
    CoinBundle(
      coins: 1500,
      priceRupees: 99,
      cardColor: Color(0xFFFFF7CE), // Pastel yellow
      buttonColor: Colors.white,
      buttonTextColor: AppColors.textBlack,
    ),
    CoinBundle(
      coins: 9000,
      priceRupees: 580,
      isPopular: true,
      badgeText: 'POPULAR',
      cardColor: Color(0xFFBAE6FD), // Light blue
      buttonColor: Colors.white,
      buttonTextColor: AppColors.textBlack,
    ),
    CoinBundle(
      coins: 16000,
      priceRupees: 999,
      isPopular: true,
      badgeText: 'BEST VALUE',
      cardColor: Color(0xFFFFD1DC), // Soft Pink
      buttonColor: Colors.white,
      buttonTextColor: AppColors.textBlack,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSelectBundle(CoinBundle bundle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => DummyPaymentGatewaySheet(
        bundle: bundle,
        onPaymentSuccess: (coins) async {
          final success = await widget.viewModel.addCoins(coins);
          if (mounted && success) {
            showNeoToast(
              context,
              '🎉 Added +${bundle.formattedCoins} Coins to your wallet! 🪙',
            );
            Navigator.of(context).maybePop();
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final currentCoins = widget.viewModel.walletCoins;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFBF8EE), // Warm soft cream
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: AppColors.strokeBlack, width: 3.0),
              left: BorderSide(color: AppColors.strokeBlack, width: 3.0),
              right: BorderSide(color: AppColors.strokeBlack, width: 3.0),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.strokeBlack,
                offset: Offset(0, -5),
                blurRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.strokeBlack.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            ScaleTransition(
                              scale: _pulseScale,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE5E5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.strokeBlack,
                                    width: 2.0,
                                  ),
                                  boxShadow: AppTheme.neoShadow(
                                    offset: const Offset(1.5, 1.5),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.title ?? 'Wallet Empty! 🪙',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 2.0,
                            ),
                            boxShadow: AppTheme.neoShadow(
                              offset: const Offset(1.5, 1.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Zero Balance Status Alert Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2), // Soft Coral Alert
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE11D48),
                        width: 2.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.strokeBlack,
                          offset: Offset(2.5, 2.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '0 COINS',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message ??
                                'Your wallet balance is $currentCoins coins. Recharge now to make voice calls and connect with listeners!',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF881337),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Quick Recharge Packs
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose a Coin Pack to Recharge:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick Bundles List / Grid
                  Column(
                    children: _bundles.map((bundle) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildBundleRow(bundle),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Action: View Full Store Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).maybePop();
                      widget.viewModel.setTab(1); // Switch to Coins tab
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2444), // Brand Dark
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.strokeBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🛒', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Open Full Coins Store',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBundleRow(CoinBundle bundle) {
    return GestureDetector(
      onTap: () => _onSelectBundle(bundle),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bundle.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.strokeBlack,
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.strokeBlack,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Coin Bank Icon / 🪙
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.0,
                    ),
                    boxShadow: AppTheme.neoShadow(
                      offset: const Offset(1.5, 1.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🪙', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),

                // Coin details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bundle.formattedCoins} Coins',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Instant recharge pack',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),

                // Price Button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.2,
                    ),
                    boxShadow: AppTheme.neoShadow(
                      offset: const Offset(2, 2),
                    ),
                  ),
                  child: Text(
                    '₹ ${bundle.priceRupees}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Optional Popular Badge
          if (bundle.badgeText != null)
            Positioned(
              top: -8,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7047EB), // Purple badge
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.strokeBlack,
                    width: 1.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.strokeBlack,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  bundle.badgeText!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
