import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/gabby_mascot_widget.dart';
import '../widgets/toast_utils.dart';

class CountryItem {
  final String name;
  final String code;
  final String flag;

  const CountryItem({
    required this.name,
    required this.code,
    required this.flag,
  });
}

class PhoneNumberView extends StatefulWidget {
  final RegistrationViewModel viewModel;

  const PhoneNumberView({
    super.key,
    required this.viewModel,
  });

  @override
  State<PhoneNumberView> createState() => _PhoneNumberViewState();
}

class _PhoneNumberViewState extends State<PhoneNumberView> {
  late final TextEditingController _phoneController;

  static const List<CountryItem> _supportedCountries = [
    CountryItem(name: 'India', code: '+91', flag: '🇮🇳'),
    CountryItem(name: 'United States', code: '+1', flag: '🇺🇸'),
    CountryItem(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
    CountryItem(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪'),
    CountryItem(name: 'Canada', code: '+1', flag: '🇨🇦'),
    CountryItem(name: 'Australia', code: '+61', flag: '🇦🇺'),
    CountryItem(name: 'Singapore', code: '+65', flag: '🇸🇬'),
    CountryItem(name: 'Saudi Arabia', code: '+966', flag: '🇸🇦'),
    CountryItem(name: 'Germany', code: '+49', flag: '🇩🇪'),
  ];

  late CountryItem _selectedCountry;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.viewModel.phoneNumber,
    );

    // Initialize country from viewModel or default to India (+91)
    final existingCode = widget.viewModel.countryCode;
    _selectedCountry = _supportedCountries.firstWhere(
      (c) => c.code == existingCode,
      orElse: () => _supportedCountries.first, // India +91
    );
    widget.viewModel.setCountryCode(_selectedCountry.code);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.strokeBlack, width: 2.2),
          boxShadow: AppTheme.neoShadow(offset: const Offset(0, -4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.strokeBlack.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Country',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _supportedCountries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final country = _supportedCountries[index];
                  final isSelected = country.code == _selectedCountry.code &&
                      country.name == _selectedCountry.name;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.textBlack,
                      ),
                    ),
                    trailing: Text(
                      country.code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? const Color(0xFF00A79D) : AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      widget.viewModel.setCountryCode(country.code);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleSendCode() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showNeoToast(context, 'Please enter your mobile number', isError: true);
      return;
    }
    if (_selectedCountry.code == '+91' && phone.length != 10) {
      showNeoToast(context, 'Please enter a valid 10-digit mobile number', isError: true);
      return;
    }
    if (phone.length < 7) {
      showNeoToast(context, 'Please enter a valid phone number', isError: true);
      return;
    }

    widget.viewModel.setPhoneNumber(phone);
    widget.viewModel.submitPhoneNumber();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Header Title
          Text(
            "What's your\nnumber?",
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            "We'll send a code to verify you.",
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 18),

          // Center Animated Mascot with Phone Handset
          const GabbyMascotWidget(
            pose: MascotPose.phoneCall,
            size: 200,
          ),

          const SizedBox(height: 24),

          // Phone Number Input Container (Country Pill + Text Field)
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.strokeBlack,
                width: 2.2,
              ),
              boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Row(
              children: [
                // Country Code Selector Pill
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 1.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _selectedCountry.code,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 20,
                          color: AppColors.textBlack,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        _selectedCountry.code == '+91' ? 10 : 15,
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textBlack,
                      letterSpacing: 0.8,
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedCountry.code == '+91'
                          ? 'Enter 10-digit number'
                          : 'Enter mobile number',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _phoneController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                _phoneController.clear();
                                vm.setPhoneNumber('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      vm.setPhoneNumber(val);
                      setState(() {});
                    },
                    onSubmitted: (_) => _handleSendCode(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Send Verification Code CTA Button (Teal Pill Button)
          GestureDetector(
            onTap: vm.isLoading ? null : _handleSendCode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF00A79D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.strokeBlack,
                  width: 2.2,
                ),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Center(
                child: vm.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Send Verification Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.mark_email_read_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
