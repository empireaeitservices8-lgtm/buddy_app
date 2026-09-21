// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';

class SlideToActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onCompleted;
  final bool isLoading;
  final double height;
  final IconData icon;
  final Color backgroundColor;
  final Color handleColor;
  final Color textColor;
  final Color iconColor;

  const SlideToActionButton({
    super.key,
    required this.text,
    required this.onCompleted,
    this.isLoading = false,
    this.height = 62.0,
    this.icon = Icons.phone,
    this.backgroundColor = AppColors.buttonDark,
    this.handleColor = AppColors.accentLavender,
    this.textColor = AppColors.buttonTextLight,
    this.iconColor = AppColors.strokeBlack,
  });

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didUpdateWidget(SlideToActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset if loading just stopped and action wasn't successful or navigating
    if (oldWidget.isLoading && !widget.isLoading) {
      _snapBack();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _snapBack({Duration duration = const Duration(milliseconds: 320)}) {
    if (!mounted) return;
    _isFinished = false;
    _animController.stop();
    _animController.duration = duration;
    _animation =
        Tween<double>(begin: _dragValue, end: 0.0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _dragValue = _animation.value;
            });
          }
        });
    _animController.forward(from: 0.0);
  }

  void _completeSlide(double maxDrag) {
    if (_isFinished || widget.isLoading) return;
    _isFinished = true;
    HapticFeedback.mediumImpact();

    _animController.stop();
    _animController.duration = const Duration(milliseconds: 180);
    _animation =
        Tween<double>(begin: _dragValue, end: maxDrag).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _dragValue = _animation.value;
            });
          }
        });

    _animController.forward(from: 0.0).then((_) {
      widget.onCompleted();
      // Smoothly animate back to normal starting position
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _snapBack(duration: const Duration(milliseconds: 350));
        }
      });
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (widget.isLoading || _isFinished || _animController.isAnimating) return;
    setState(() {
      _dragValue = (_dragValue + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (widget.isLoading || _isFinished) return;
    if (_dragValue >= maxDrag * 0.70) {
      _completeSlide(maxDrag);
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final handleSize = widget.height - 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - handleSize - 12).clamp(
          0.0,
          double.infinity,
        );

        return GestureDetector(
          // Allow tapping anywhere on the bar to trigger the slide completion
          onTap: () {
            if (!widget.isLoading && !_isFinished) {
              _completeSlide(maxDrag);
            }
          },
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: AppColors.strokeBlack,
                width: AppTheme.strokeWidth,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Center Label with subtle fade on drag
                Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentLavender,
                            ),
                          ),
                        )
                      : Opacity(
                          opacity: maxDrag > 0
                              ? (1.0 - (_dragValue / maxDrag)).clamp(0.15, 1.0)
                              : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 54.0,
                            ),
                            child: Text(
                              widget.text,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.buttonText.copyWith(
                                color: widget.textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                ),

                // Draggable handle
                if (!widget.isLoading)
                  Positioned(
                    left: 6 + _dragValue,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          _onDragUpdate(details, maxDrag),
                      onHorizontalDragEnd: (details) =>
                          _onDragEnd(details, maxDrag),
                      child: Container(
                        width: handleSize,
                        height: handleSize,
                        decoration: BoxDecoration(
                          color: widget.handleColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.strokeBlack.withOpacity(0.2),
                              offset: const Offset(1, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.iconColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
