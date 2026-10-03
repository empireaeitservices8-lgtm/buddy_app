import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/cartoon_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/slide_to_action.dart';
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

  const PhoneNumberView({super.key, required this.viewModel});

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
          color: CartoonColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: CartoonColors.charcoal,
            width: CartoonDimensions.borderWidthThin,
          ),
          boxShadow: CartoonDimensions.shadow(offset: const Offset(0, -4)),
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
                  color: CartoonColors.charcoal.withValues(alpha: 0.2),
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
                color: CartoonColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _supportedCountries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final country = _supportedCountries[index];
                  final isSelected =
                      country.code == _selectedCountry.code &&
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
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: CartoonColors.charcoal,
                      ),
                    ),
                    trailing: Text(
                      country.code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? const Color(0xFF00A79D)
                            : CartoonColors.textMuted,
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
      showNeoToast(
        context,
        'Please enter a valid 10-digit mobile number',
        isError: true,
      );
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 680;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isSmallScreen ? 12 : 24),

          // 1. Header Title (at TOP)
          Text(
            "What's your\nnumber?",
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: isSmallScreen ? 28 : 32,
              fontWeight: FontWeight.w900,
              color: CartoonColors.charcoal,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),

          // 2. Subtitle
          const Text(
            "We'll send a code to verify you.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CartoonColors.textMuted,
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // 3. Center Mascot / Illustration (in the MIDDLE)
          Container(
            width: isSmallScreen ? 175 : 205,
            height: isSmallScreen ? 175 : 205,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/images/welcome.jpeg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 20 : 28),

          // 4. Phone Number Input Container (Country Pill + Text Field)
          Container(
            decoration: BoxDecoration(
              color: CartoonColors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: CartoonColors.charcoal,
                width: CartoonDimensions.borderWidthThin,
              ),
              boxShadow: CartoonDimensions.shadowSmall(
                offset: const Offset(3.0, 3.0),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        color: CartoonColors.charcoal,
                        width: 1.5,
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
                            color: CartoonColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 20,
                          color: CartoonColors.charcoal,
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
                      color: CartoonColors.charcoal,
                      letterSpacing: 0.8,
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedCountry.code == '+91'
                          ? 'Enter 10-digit number'
                          : 'Enter mobile number',
                      hintStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: CartoonColors.textPlaceholder,
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
                                color: CartoonColors.textPlaceholder,
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

          SizedBox(height: isSmallScreen ? 16 : 22),

          // 5. Slide To Action Button
          SlideToActionButton(
            text: 'SLIDE TO GET OTP',
            icon: Icons.arrow_forward_rounded,
            backgroundColor: CartoonColors.charcoal,
            handleColor: CartoonColors.lime,
            textColor: Colors.white,
            iconColor: CartoonColors.charcoal,
            height: 64.0,
            isLoading: vm.isLoading,
            onCompleted: _handleSendCode,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

