import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/cartoon_theme.dart';

/// NeubrutalTextField:
/// - Encloses text inputs in rounded 3px charcoal-bordered containers with offset shadows
/// - Preserves TextEditingControllers, onChanged callbacks, formatters, and validators
class NeubrutalTextField extends StatelessWidget {
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
  final int? maxLines;
  final int? minLines;
  final Color backgroundColor;

  const NeubrutalTextField({
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
    this.maxLines = 1,
    this.minLines,
    this.backgroundColor = CartoonColors.cardWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: CartoonColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(CartoonTheme.buttonRadius),
            border: Border.all(
              color: CartoonColors.charcoal,
              width: CartoonTheme.borderWidth,
            ),
            boxShadow: CartoonTheme.shadow(offset: const Offset(3.5, 3.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ?prefixWidget,
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  autofocus: autofocus,
                  maxLines: maxLines,
                  minLines: minLines,
                  inputFormatters: inputFormatters,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: CartoonColors.charcoal,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
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
