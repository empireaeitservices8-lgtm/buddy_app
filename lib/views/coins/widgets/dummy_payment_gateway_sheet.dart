// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../coins_store_screen.dart';

enum PGStep { selectMethod, processing, success }

enum PaymentCategory { upi, card, netbanking, wallet }

class DummyPaymentGatewaySheet extends StatefulWidget {
  final CoinBundle bundle;
  final Future<bool> Function(int coins) onPaymentSuccess;

  const DummyPaymentGatewaySheet({
    super.key,
    required this.bundle,
    required this.onPaymentSuccess,
  });

  @override
  State<DummyPaymentGatewaySheet> createState() => _DummyPaymentGatewaySheetState();
}

class _DummyPaymentGatewaySheetState extends State<DummyPaymentGatewaySheet> {
  PGStep _currentStep = PGStep.selectMethod;
  PaymentCategory _selectedCategory = PaymentCategory.upi;
  String _selectedUpiApp = 'Google Pay';
  String _selectedBank = 'HDFC Bank';
  String _selectedWallet = 'Paytm Wallet';
  bool _isCustomUpi = false;

  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _cardNumberController =
      TextEditingController(text: '4532  8821  9012  4491');
  final TextEditingController _expiryController =
      TextEditingController(text: '08/29');
  final TextEditingController _cvvController = TextEditingController(text: '721');
  final TextEditingController _cardHolderController =
      TextEditingController(text: 'SAMUEL K');

  late final String _orderId;
  late final String _txnId;
  String _processingMessage = 'Initiating 256-bit encrypted handshake...';
  int _processingProgress = 25;
  Timer? _processingTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().millisecondsSinceEpoch;
    _orderId = 'ORD_${now.toString().substring(6)}';
    _txnId = 'TXN_${(now + 98765).toString().substring(4)}';
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _startPaymentSimulation() {
    setState(() {
      _currentStep = PGStep.processing;
      _processingProgress = 20;
      _processingMessage = 'Securing connection with bank gateway...';
    });

    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _processingProgress = 55;
        _processingMessage = 'Awaiting authorization from $_selectedUpiApp...';
      });

      _processingTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _processingProgress = 90;
          _processingMessage = 'Verifying settlement & crediting coins...';
        });

        _processingTimer = Timer(const Duration(milliseconds: 600), () async {
          if (!mounted) return;
          final success = await widget.onPaymentSuccess(widget.bundle.coins);
          if (mounted) {
            setState(() {
              _processingProgress = 100;
              _currentStep = PGStep.success;
            });
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Ultra-clean premium canvas
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.strokeBlack, width: 2.2),
        boxShadow: AppTheme.neoShadow(offset: const Offset(0, -6)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Gateway Navbar
            _buildGatewayHeader(),

            // Dynamic Step View
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStepView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.strokeBlack, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Drag Notch
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'GABBYTALK PAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Ref: $_orderId',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'TEST MODE',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case PGStep.selectMethod:
        return _buildMethodSelectView();
      case PGStep.processing:
        return _buildProcessingView();
      case PGStep.success:
        return _buildSuccessView();
    }
  }

  Widget _buildMethodSelectView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Voucher Card
          _buildOrderSummaryVoucher(),
          const SizedBox(height: 18),

          // Categories Segment Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYMENT OPTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textBlack.withOpacity(0.55),
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    '100% Safe Checkout',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryTab(PaymentCategory.upi, '⚡ UPI Apps', const Color(0xFFE0F2FE)),
                const SizedBox(width: 8),
                _buildCategoryTab(PaymentCategory.card, '💳 Cards', const Color(0xFFF3E8FF)),
                const SizedBox(width: 8),
                _buildCategoryTab(PaymentCategory.netbanking, '🏛️ Net Banking', const Color(0xFFFEF3C7)),
                const SizedBox(width: 8),
                _buildCategoryTab(PaymentCategory.wallet, '👛 Wallets', const Color(0xFFFCE7F3)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content of Selected Category
          if (_selectedCategory == PaymentCategory.upi) _buildUpiSection(),
          if (_selectedCategory == PaymentCategory.card) _buildCardSection(),
          if (_selectedCategory == PaymentCategory.netbanking) _buildNetBankingSection(),
          if (_selectedCategory == PaymentCategory.wallet) _buildWalletSection(),

          const SizedBox(height: 20),

          // Pay Button (Razorpay Indigo / Emerald Gradient)
          GestureDetector(
            onTap: _startPaymentSimulation,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'PAY ₹${widget.bundle.priceRupees} SECURELY',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Trust Badge Footer
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '256-Bit SSL • PCI-DSS Level 1 • Powered by GabbyPay',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryVoucher() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.strokeBlack, width: 1.8),
        boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7CE),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.strokeBlack, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🪙', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.bundle.formattedCoins} Coins Pack',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Instant Credit ⚡',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹ ${widget.bundle.priceRupees}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Inc. of all taxes',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ticket dotted divider line
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
                  height: 1.2,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Merchant: GabbyTalk Media',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Text(
                  'No extra conv. fees',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(PaymentCategory category, String label, Color activeBg) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.strokeBlack : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? AppTheme.neoShadow(offset: const Offset(1.5, 1.5))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? AppColors.textBlack : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildUpiSection() {
    final upiApps = [
      {
        'id': 'Google Pay',
        'name': 'Google Pay',
        'subtitle': 'Fastest UPI checkout (GPay)',
        'badgeColor': const Color(0xFFEA4335),
        'logoWidget': _buildGPayLogo(),
      },
      {
        'id': 'PhonePe',
        'name': 'PhonePe UPI',
        'subtitle': 'Pay via PhonePe app / linked bank',
        'badgeColor': const Color(0xFF5F259F),
        'logoWidget': _buildPhonePeLogo(),
      },
      {
        'id': 'Paytm',
        'name': 'Paytm UPI',
        'subtitle': 'Paytm Payments Bank or UPI ID',
        'badgeColor': const Color(0xFF00BAF2),
        'logoWidget': _buildPaytmLogo(),
      },
      {
        'id': 'BHIM UPI',
        'name': 'BHIM UPI',
        'subtitle': 'NPCI Official UPI Interface',
        'badgeColor': const Color(0xFF00796B),
        'logoWidget': _buildBhimLogo(),
      },
    ];

    return Column(
      children: [
        ...upiApps.map((app) {
          final isSelected = !_isCustomUpi && _selectedUpiApp == app['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _isCustomUpi = false;
                _selectedUpiApp = app['id'] as String;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300,
                  width: isSelected ? 2.0 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  app['logoWidget'] as Widget,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBlack,
                          ),
                        ),
                        Text(
                          app['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade400,
                        width: isSelected ? 2 : 1.5,
                      ),
                      color: isSelected ? const Color(0xFF16A34A) : Colors.white,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),

        // Custom UPI ID Field
        GestureDetector(
          onTap: () => setState(() => _isCustomUpi = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isCustomUpi ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCustomUpi ? const Color(0xFF16A34A) : Colors.grey.shade300,
                width: _isCustomUpi ? 2.0 : 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7CE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.strokeBlack, width: 1.2),
                          ),
                          alignment: Alignment.center,
                          child: const Text('@', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter UPI ID / VPA',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textBlack,
                              ),
                            ),
                            Text(
                              'e.g. mobile@okhdfcbank, name@upi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isCustomUpi ? const Color(0xFF16A34A) : Colors.grey.shade400,
                          width: _isCustomUpi ? 2 : 1.5,
                        ),
                        color: _isCustomUpi ? const Color(0xFF16A34A) : Colors.white,
                      ),
                      child: _isCustomUpi
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                if (_isCustomUpi) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _upiIdController,
                    decoration: InputDecoration(
                      hintText: 'yourname@upi',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.strokeBlack, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'VERIFY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGPayLogo() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'GPay',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }

  Widget _buildPhonePeLogo() {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF5F259F),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'पे',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPaytmLogo() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF002E6E),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Paytm',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Color(0xFF00BAF2),
        ),
      ),
    );
  }

  Widget _buildBhimLogo() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF00796B),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'BHIM',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.strokeBlack, width: 1.6),
        boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credit / Debit Card',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textBlack,
                ),
              ),
              Row(
                children: [
                  _buildCardBadge('VISA', const Color(0xFF1A1F71), Colors.white),
                  const SizedBox(width: 4),
                  _buildCardBadge('Mastercard', const Color(0xFFEB001B), Colors.white),
                  const SizedBox(width: 4),
                  _buildCardBadge('RuPay', const Color(0xFF0F75BD), Colors.white),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Card Number
          _buildInputLabel('CARD NUMBER'),
          TextField(
            controller: _cardNumberController,
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.strokeBlack, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.strokeBlack, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Expiry and CVV Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('EXPIRY (MM/YY)'),
                    TextField(
                      controller: _expiryController,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.strokeBlack, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('CVV / CVC'),
                    TextField(
                      controller: _cvvController,
                      obscureText: true,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.strokeBlack, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card Holder Name
          _buildInputLabel('CARD HOLDER NAME'),
          TextField(
            controller: _cardHolderController,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.strokeBlack, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildNetBankingSection() {
    final banks = [
      {'name': 'HDFC Bank', 'badge': 'Most Popular'},
      {'name': 'State Bank of India', 'badge': 'Fast'},
      {'name': 'ICICI Bank', 'badge': 'Instant'},
      {'name': 'Axis Bank', 'badge': 'Direct'},
      {'name': 'Kotak Mahindra', 'badge': 'Instant'},
    ];

    return Column(
      children: banks.map((b) {
        final isSelected = _selectedBank == b['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedBank = b['name']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🏛️', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      b['name']!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b['badge']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: isSelected ? const Color(0xFFD97706) : Colors.white,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWalletSection() {
    final wallets = [
      {'name': 'Paytm Wallet', 'icon': '👛', 'cashback': '₹15 Cashback'},
      {'name': 'Amazon Pay Balance', 'icon': '📦', 'cashback': 'Fast OTP'},
      {'name': 'MobiKwik ZIP', 'icon': '⚡', 'cashback': 'Pay Later'},
      {'name': 'Freecharge', 'icon': '⚡', 'cashback': 'Instant'},
    ];

    return Column(
      children: wallets.map((w) {
        final isSelected = _selectedWallet == w['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedWallet = w['name']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFDF2F8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFDB2777) : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(w['icon']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(
                      w['name']!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        w['cashback']!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBE185D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFDB2777) : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: isSelected ? const Color(0xFFDB2777) : Colors.white,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProcessingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: _processingProgress / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.shield_outlined,
                  size: 32,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Processing Secure Payment...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _processingMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),

          // Transaction Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.strokeBlack, width: 1.4),
              boxShadow: AppTheme.neoShadow(offset: const Offset(1.5, 1.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💳', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Amount: ₹${widget.bundle.priceRupees}  •  $_selectedUpiApp',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textBlack,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Auto-confirming in a few seconds...',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeBlack, width: 2.2),
              boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: Color(0xFF15803D),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '+${widget.bundle.formattedCoins} Coins Added to Wallet',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Receipt Voucher
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.strokeBlack, width: 1.6),
              boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
            ),
            child: Column(
              children: [
                _buildReceiptRow('Amount Paid', '₹ ${widget.bundle.priceRupees}.00'),
                const Divider(height: 14, thickness: 1),
                _buildReceiptRow('Transaction ID', _txnId),
                const Divider(height: 14, thickness: 1),
                _buildReceiptRow('Payment Method', _selectedUpiApp),
                const Divider(height: 14, thickness: 1),
                _buildReceiptRow(
                  'Payment Status',
                  'SUCCESSFUL ✅',
                  valueColor: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Done Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFAEC4FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'RETURN TO STORE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textBlack,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.textBlack,
          ),
        ),
      ],
    );
  }
}
