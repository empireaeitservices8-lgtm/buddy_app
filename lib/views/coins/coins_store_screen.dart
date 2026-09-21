// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/home_view_model.dart';
import '../widgets/toast_utils.dart';
import 'widgets/dummy_payment_gateway_sheet.dart';

class CoinBundle {
  final int coins;
  final int priceRupees;
  final bool isPopular;
  final String? badgeText;
  final Color? cardColor;
  final Color? buttonColor;
  final Color? buttonTextColor;

  const CoinBundle({
    required this.coins,
    required this.priceRupees,
    this.isPopular = false,
    this.badgeText,
    this.cardColor,
    this.buttonColor,
    this.buttonTextColor,
  });

  String get formattedCoins {
    return coins.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class CoinsStoreScreen extends StatefulWidget {
  final HomeViewModel viewModel;
  final bool isTab;

  const CoinsStoreScreen({
    super.key,
    required this.viewModel,
    this.isTab = false,
  });

  @override
  State<CoinsStoreScreen> createState() => _CoinsStoreScreenState();
}

class _CoinsStoreScreenState extends State<CoinsStoreScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.fetchCoinsBalance(silent: true);
    widget.viewModel.fetchCoinHistory(silent: true);
  }

  final List<CoinBundle> _bundles = const [
    CoinBundle(
      coins: 1500,
      priceRupees: 99,
      cardColor: Color(0xFFFFFFFF),
      buttonColor: Color(0xFFFFF7CE),
      buttonTextColor: AppColors.textBlack,
    ),
    CoinBundle(
      coins: 9000,
      priceRupees: 580,
      isPopular: true,
      badgeText: 'POPULAR',
      cardColor: Color(0xFFE8F0FE),
      buttonColor: Color(0xFFAEC4FE),
      buttonTextColor: AppColors.textBlack,
    ),
    CoinBundle(
      coins: 18000,
      priceRupees: 999,
      isPopular: true,
      badgeText: 'BEST VALUE',
      cardColor: Color(0xFFFFB8D2),
      buttonColor: Color(0xFFE84393),
      buttonTextColor: Colors.white,
    ),
  ];

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
              'Added +${bundle.formattedCoins} Coins to your wallet! 🪙',
            );
          }
          return success;
        },
      ),
    );
  }

  void _showHistoryBottomSheet() {
    widget.viewModel.fetchCoinHistory(silent: true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final txs = widget.viewModel.coinTransactions;
          final coinHistory = widget.viewModel.coinHistory;
          final isLoading = widget.viewModel.isLoadingCoinHistory;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: AppColors.strokeBlack, width: 2.2),
              boxShadow: AppTheme.neoShadow(offset: const Offset(0, -4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Coin History 📜',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7CE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Balance: ${widget.viewModel.walletCoins} 🪙',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                if (coinHistory != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL RECHARGED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${coinHistory.totalCoinsPurchased} Coins',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL SPENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFB71C1C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '-${coinHistory.totalCoinsSpent} Coins',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (isLoading && txs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: CircularProgressIndicator(
                        color: AppColors.strokeBlack,
                      ),
                    ),
                  )
                else if (txs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          const Text(
                            'No transactions found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your recharge and call coin history will appear here.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textBlack.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: txs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = txs[index];
                        final title = item.description.isNotEmpty
                            ? item.description
                            : (item.isCredit ? 'Recharge Pack' : 'Call Spent');
                        return _buildHistoryItem(
                          title: title,
                          subtitle: '${item.status} • ID #${item.id}',
                          amount: item.formattedCoins,
                          time: item.formattedDate,
                          isCredit: item.isCredit,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    required bool isCredit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.strokeBlack, width: 1.6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$subtitle • $time',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isCredit
                  ? const Color(0xFF1B8A3E)
                  : const Color(0xFFD63031),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPurchaseBottomSheet(CoinBundle bundle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.strokeBlack, width: 2.2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(0, -4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),

          // Large Coin Icon
          _buildCoinIcon(size: 84),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Confirm Coin Bundle Purchase',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Get ${bundle.formattedCoins} Coins for ₹ ${bundle.priceRupees}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 26),

          // Pay & Add Coins Button
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              final success = await widget.viewModel.addCoins(bundle.coins);
              if (mounted) {
                showNeoToast(
                  context,
                  success
                      ? 'Added +${bundle.formattedCoins} Coins to your wallet! 🪙'
                      : 'Failed to add coins. Please try again.',
                  isError: !success,
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFAEC4FE), // Lavender pill
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
              ),
              alignment: Alignment.center,
              child: Text(
                'Pay ₹ ${bundle.priceRupees} & Add Coins 💳',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textBlack,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCoinIcon({double size = 52}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7CE), // Pale yellow circular container
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.strokeBlack, width: 1.8),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.72,
        height: size * 0.72,
        decoration: const BoxDecoration(
          color: Color(0xFFFFD54F), // Gold coin
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.account_balance_rounded,
          size: size * 0.42,
          color: const Color(0xFF6D4C00),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isTab ? Colors.transparent : AppColors.background,
      body: Stack(
        children: [
          if (!widget.isTab) ...[
            // 1. Top-Right Soft Sage Circle
            Positioned(
              top: -65,
              right: -60,
              child: Container(
                width: 270,
                height: 270,
                decoration: const BoxDecoration(
                  color: Color(0xFFC3E2A0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 2. Middle-Left Warm Peach Circle
            Positioned(
              top: 270,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8D4AF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 3. Bottom-Right Soft Lime Circle
            Positioned(
              top: 500,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  color: Color(0xFFCEF17D),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],

          SafeArea(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 10,
                    bottom: widget.isTab ? 95 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top App Bar Row: [Back Button / Store Badge] [Coins Store Title] [History 📜 Button]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!widget.isTab)
                            // Back Button
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.strokeBlack,
                                    width: 2.0,
                                  ),
                                  boxShadow: AppTheme.neoShadow(
                                    offset: const Offset(2.5, 2.5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.strokeBlack,
                                  size: 22,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7CE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.strokeBlack,
                                  width: 1.8,
                                ),
                                boxShadow: AppTheme.neoShadow(
                                  offset: const Offset(2, 2),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🪙', style: TextStyle(fontSize: 13)),
                                  SizedBox(width: 5),
                                  Text(
                                    'COINS STORE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Center Title
                          const Text(
                            'Coins Store',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlack,
                              letterSpacing: -0.5,
                            ),
                          ),

                          // Spacing placeholder to keep title centered
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Premium Wallet Card
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF5A45E5),
                              Color(0xFF9E44C5),
                              Color(0xFFEA4393),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 2.2,
                          ),
                          boxShadow: AppTheme.neoShadow(
                            offset: const Offset(3.5, 3.5),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Translucent Coin Watermark in Background
                            Positioned(
                              right: -15,
                              top: -10,
                              bottom: -10,
                              child: Opacity(
                                opacity: 0.15,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.account_balance_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            // Content inside Card
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top Row: Wallet Icon & "Premium Wallet"
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Premium Wallet',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Bottom Balance
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'YOUR BALANCE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(0.8),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '${widget.viewModel.walletCoins}',
                                            style: const TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Coins',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Section Title: "SELECT COIN BUNDLE"
                      Text(
                        'SELECT COIN BUNDLE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack.withOpacity(0.65),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2x2 Grid of Coin Bundles
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bundles.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                        itemBuilder: (context, index) {
                          return _buildBundleCard(_bundles[index]);
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleCard(CoinBundle bundle) {
    final cardColor = bundle.cardColor ?? AppColors.cardWhite;
    final buttonColor = bundle.buttonColor ?? const Color(0xFFFFF7CE);
    final buttonTextColor = bundle.buttonTextColor ?? AppColors.textBlack;

    return GestureDetector(
      onTap: () => _onSelectBundle(bundle),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.strokeBlack, width: 2.0),
              boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 2),
                // Coin Badge
                _buildCoinIcon(size: 54),

                // Coins Amount
                Text(
                  '${bundle.formattedCoins} Coins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textBlack,
                  ),
                ),

                // Price Button
                Container(
                  width: double.infinity,
                  height: 42,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '₹ ${bundle.priceRupees}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: buttonTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pill Badge (e.g. POPULAR / BEST VALUE)
          if (bundle.isPopular || bundle.badgeText != null)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: bundle.badgeText == 'BEST VALUE'
                      ? const Color(0xFFE84393) // Hot pink for best value
                      : const Color(0xFF7047EB), // Purple pill for popular
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.strokeBlack, width: 1.6),
                ),
                child: Text(
                  bundle.badgeText ?? 'POPULAR',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
