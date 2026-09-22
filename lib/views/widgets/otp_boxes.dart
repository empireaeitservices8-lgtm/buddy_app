// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';

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
    final boxSize = widget.length > 4 ? 50.0 : 66.0;
    final fontSize = widget.length > 4 ? 22.0 : 26.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final hasValue = _controllers[index].text.isNotEmpty;

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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE0F2FE), // Soft sky
                    Color(0xFFFFE4E6), // Soft peach/pink
                    Color(0xFFFEF3C7), // Soft yellow
                    Color(0xFFD1FAE5), // Soft mint
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.strokeBlack,
                  width: isFocused ? 2.6 : 2.0,
                ),
                boxShadow: AppTheme.neoShadow(
                  offset: isFocused ? const Offset(1.5, 1.5) : const Offset(3.0, 3.0),
                ),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                showCursor: isFocused,
                cursorColor: const Color(0xFF00A79D),
                cursorWidth: 2.2,
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
