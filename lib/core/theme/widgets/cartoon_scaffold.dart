import 'package:flutter/material.dart';
import '../cartoon_colors.dart';
import 'cartoon_background.dart';

/// Reusable Cartoon Scaffold for Screens
class CartoonScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBlobs;
  final bool showDots;
  final bool resizeToAvoidBottomInset;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool extendBody;

  const CartoonScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showBlobs = true,
    this.showDots = true,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor = CartoonColors.canvas,
    this.padding,
    this.extendBody = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: CartoonBackground(
        showBlobs: showBlobs,
        showDots: showDots,
        backgroundColor: backgroundColor,
        child: content,
      ),
    );
  }
}
