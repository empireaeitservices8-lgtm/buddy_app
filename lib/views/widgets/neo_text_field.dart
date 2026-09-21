// ignore_for_file: deprecated_member_use

import 'package:buddy_app/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class NeoTextField extends StatelessWidget {
  final String? label;
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixWidget;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  const NeoTextField({
    super.key,
    this.label,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixWidget,
    this.inputFormatters,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.labelUppercase),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.strokeBlack, width: 2.0),
          ),
          child: Row(
            children: [
              ?prefixWidget,
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  autofocus: autofocus,
                  inputFormatters: inputFormatters,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.textPlaceholder,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    suffixIcon: suffixIcon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NeoPhoneField extends StatelessWidget {
  final String countryCode;
  final List<String> countryCodes;
  final ValueChanged<String> onCountryCodeChanged;
  final TextEditingController? controller;
  final ValueChanged<String> onPhoneNumberChanged;
  final int maxLength;

  const NeoPhoneField({
    super.key,
    required this.countryCode,
    required this.countryCodes,
    required this.onCountryCodeChanged,
    this.controller,
    required this.onPhoneNumberChanged,
    this.maxLength = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.strokeBlack, width: 2.0),
      ),
      child: Row(
        children: [
          // Country Code dropdown button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: countryCode,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.strokeBlack,
                  ),
                ),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textBlack,
                ),
                dropdownColor: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                items: countryCodes.map((code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(code),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onCountryCodeChanged(val);
                },
              ),
            ),
          ),

          // Vertical divider line
          Container(
            height: 28,
            width: 1.5,
            color: AppColors.strokeBlack.withOpacity(0.3),
            margin: const EdgeInsets.only(right: 6),
          ),

          // Phone Number input
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onPhoneNumberChanged,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(maxLength),
              ],
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
                color: AppColors.textBlack,
              ),
              decoration: const InputDecoration(
                hintText: AppStrings.phonePlaceholder,
                hintStyle: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
