// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  const OtpInputField({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() {
        if (mounted) setState(() {});
      });
    }

    // Auto-focus first box after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getCurrentCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted content or multiple chars
      final cleanVal = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length; i++) {
        if (i < cleanVal.length) {
          _controllers[i].text = cleanVal[i];
        } else {
          _controllers[i].text = '';
        }
      }
      final current = _getCurrentCode();
      widget.onChanged?.call(current);
      if (current.length == widget.length) {
        _focusNodes[widget.length - 1].unfocus();
        widget.onCompleted(current);
      } else if (cleanVal.length < widget.length) {
        _focusNodes[cleanVal.length].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      // Backspaced / deleted empty field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    final code = _getCurrentCode();
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
    setState(() {});
  }

  void _onKeyEvent(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].text = '';
      final code = _getCurrentCode();
      widget.onChanged?.call(code);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.length > 4 ? 48.0 : 70.0;
    final borderRadius = widget.length > 4 ? 16.0 : 22.0;
    final fontSize = widget.length > 4 ? 22.0 : 28.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final _ = _controllers[index].text.isNotEmpty;

        return RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (event) => _onKeyEvent(index, event),
          child: GestureDetector(
            onTap: () {
              _focusNodes[index].requestFocus();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: isFocused
                    ? const Color(0xFFE8EDFF)
                    : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFF8C9DFF)
                      : AppColors.strokeBlack,
                  width: isFocused ? 2.2 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.strokeBlack.withOpacity(0.12),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                showCursor: isFocused,
                cursorColor: const Color(0xFF6B82FF),
                cursorWidth: 2.0,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: fontSize,
                  color: AppColors.textBlack,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => _onChanged(index, val),
              ),
            ),
          ),
        );
      }),
    );
  }
}
