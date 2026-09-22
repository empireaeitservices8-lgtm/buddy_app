// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/home_view_model.dart';
import '../widgets/neo_background.dart';
import '../widgets/toast_utils.dart';
import 'widgets/dummy_payment_gateway_sheet.dart';

class CoinBundle {
  final int coins;
  final int priceRupees;
  final bool isPopular;
  final String? badgeText;
  final Color cardColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const CoinBundle({
    required this.coins,
    required this.priceRupees,
    this.isPopular = false,
    this.badgeText,
    required this.cardColor,
    this.buttonColor = Colors.white,
    this.buttonTextColor = AppColors.textBlack,
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
      cardColor: Color(0xFFFFD1DC), // Pink
      buttonColor: Colors.white,
      buttonTextColor: AppColors.textBlack,
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
              border: Border.all(color: AppColors.strokeBlack, width: 3.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.strokeBlack,
                  offset: Offset(0, -4),
                  blurRadius: 0,
                ),
              ],
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
                      color: AppColors.strokeBlack,
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
                          width: 2.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.strokeBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
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
                              width: 1.8,
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
                              width: 1.8,
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
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.8,
                            ),
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
                                    '${item.status} • ${item.formattedDate}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textBlack.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                item.formattedCoins,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: item.isCredit
                                      ? const Color(0xFF1B8A3E)
                                      : const Color(0xFFD63031),
                                ),
                              ),
                            ],
                          ),
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

  /// 2D Cute Cartoon Gold Coin Bank Icon
  Widget _buildCoinBankIcon({double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Warm cream/yellow
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.strokeBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.strokeBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.72,
        height: size * 0.72,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD54F), // Gold coin bank body
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.strokeBlack, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.account_balance_rounded,
          size: size * 0.40,
          color: const Color(0xFF5D4037),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final balance = widget.viewModel.walletCoins;
          final displayBalance = balance > 0 ? balance : 300;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: widget.isTab ? 95 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header: [GabbyTalk Logo / Back] & [300 Coins Badge] & [History]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Brand / Back Button
                    if (!widget.isTab)
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
                              width: 2.6,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.strokeBlack,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
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
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7CE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 2.6,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.strokeBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🪙', style: TextStyle(fontSize: 15)),
                            SizedBox(width: 6),
                            Text(
                              'Coins Store',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: AppColors.textBlack,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Right Group: [Coins Badge] & [History Button]
                    Row(
                      children: [
                        // 300 Coins Badge (Pill with 3px black border & hard shadow)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5EBAA), // Pastel mint
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 2.6,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                '$displayBalance coins',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // History 📜 Button
                        GestureDetector(
                          onTap: _showHistoryBottomSheet,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7CE),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 2.4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.strokeBlack,
                                  offset: Offset(2.5, 2.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('📜', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 2. Main Top Card: Vivid Purple-to-Pink Gradient Wallet Card
                Container(
                  width: double.infinity,
                  height: 185,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8338EC), // Vivid Purple
                        Color(0xFFFF006E), // Vivid Pink
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 3.0, // 3px black border
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.strokeBlack,
                        offset: Offset(4, 4), // Hard offset drop shadow
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Translucent Coin Bank Watermark in Background
                      Positioned(
                        right: -10,
                        top: -10,
                        bottom: -10,
                        child: Opacity(
                          opacity: 0.16,
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

                      // Content inside Wallet Card
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Row: Premium Wallet Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.28),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'WALLET BALANCE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text('✨', style: TextStyle(fontSize: 18)),
                              ],
                            ),

                            // Balance Display: '300 Coins'
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$displayBalance',
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Coins',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ready for instant calls with verified listeners',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
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
                const SizedBox(height: 26),

                // 3. Section Title: "SELECT COIN BUNDLE"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECT COIN BUNDLE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7CE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'Instant Top-Up ⚡',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Grid of 3 Coin Bundle Cards (Pastel Yellow, Light Blue, Pink)
                // Row with 2 cards (Yellow & Blue)
                Row(
                  children: [
                    Expanded(child: _buildBundleCard(_bundles[0])),
                    const SizedBox(width: 14),
                    Expanded(child: _buildBundleCard(_bundles[1])),
                  ],
                ),
                const SizedBox(height: 14),

                // 3rd Featured Card (Pink - Best Value)
                _buildFeaturedBundleCard(_bundles[2]),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );

    if (widget.isTab) {
      return content;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8EE),
      body: NeoBackground(child: content),
    );
  }

  /// Grid Bundle Card (Pastel Yellow / Light Blue with 3px black outline & hard shadow)
  Widget _buildBundleCard(CoinBundle bundle) {
    return GestureDetector(
      onTap: () => _onSelectBundle(bundle),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 195,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: bundle.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.strokeBlack,
                width: 3.0, // 3px black border
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.strokeBlack,
                  offset: Offset(4, 4), // Hard shadow
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 2),
                // 2D Gold Coin Bank Icon
                _buildCoinBankIcon(size: 52),

                // Coins Amount
                Text(
                  '${bundle.formattedCoins} Coins',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textBlack,
                  ),
                ),

                // Price Pill: '₹ 99' / '₹ 580'
                Container(
                  width: double.infinity,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.6, // 3px style outline
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.strokeBlack,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '₹ ${bundle.priceRupees}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pill Badge (e.g. POPULAR)
          if (bundle.isPopular || bundle.badgeText != null)
            Positioned(
              top: -9,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7047EB), // Purple pill for popular
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.strokeBlack,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  bundle.badgeText ?? 'POPULAR',
                  style: const TextStyle(
                    fontSize: 9.5,
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

  /// 3rd Featured Bundle Card (Pink - Best Value with 3px black outline & hard shadow)
  Widget _buildFeaturedBundleCard(CoinBundle bundle) {
    return GestureDetector(
      onTap: () => _onSelectBundle(bundle),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bundle.cardColor, // Pink
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.strokeBlack,
                width: 3.0, // 3px black border
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.strokeBlack,
                  offset: Offset(4, 4), // Hard shadow
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // 2D Gold Coin Bank Icon
                _buildCoinBankIcon(size: 60),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bundle.formattedCoins} Coins',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Maximum savings for continuous calling',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Price Pill: '₹ 999'
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.6,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.strokeBlack,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    '₹ ${bundle.priceRupees}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pill Badge (e.g. BEST VALUE)
          if (bundle.badgeText != null)
            Positioned(
              top: -9,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE84393), // Hot pink for best value
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.0),
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
                    fontSize: 9.5,
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
