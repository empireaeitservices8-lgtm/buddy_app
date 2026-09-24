import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cartoon_colors.dart';
import '../cartoon_dimensions.dart';
import '../cartoon_text_theme.dart';

/// Cartoon Text Input Field with Thick Ink Outline, 20px Radius & Hard Shadow
class CartoonTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry contentPadding;
  final VoidCallback? onTap;

  const CartoonTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    this.onTap,
  });

  @override
  State<CartoonTextField> createState() => _CartoonTextFieldState();
}

class _CartoonTextFieldState extends State<CartoonTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = (widget.errorText != null && widget.errorText!.isNotEmpty) ||
        (_localError != null && _localError!.isNotEmpty);

    final borderColor = hasError
        ? CartoonColors.error
        : (_isFocused ? CartoonColors.primary : CartoonColors.ink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: const TextStyle(
              fontFamily: CartoonTextTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: CartoonColors.ink,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: widget.enabled ? CartoonColors.white : const Color(0xFFF3F1EC),
            borderRadius: BorderRadius.circular(CartoonDimensions.inputRadius),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? CartoonDimensions.borderWidthThick : CartoonDimensions.borderWidth,
            ),
            boxShadow: CartoonDimensions.shadowSmall(offset: const Offset(2.5, 2.5)),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            onTap: widget.onTap,
            onChanged: (val) {
              if (_localError != null) {
                setState(() => _localError = null);
              }
              widget.onChanged?.call(val);
            },
            onFieldSubmitted: widget.onSubmitted,
            validator: (val) {
              final res = widget.validator?.call(val);
              setState(() => _localError = res);
              return res;
            },
            style: const TextStyle(
              fontFamily: CartoonTextTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CartoonColors.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontFamily: CartoonTextTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CartoonColors.textPlaceholder,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding: widget.contentPadding,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              counterText: '',
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              widget.errorText ?? _localError!,
              style: const TextStyle(
                fontFamily: CartoonTextTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CartoonColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
