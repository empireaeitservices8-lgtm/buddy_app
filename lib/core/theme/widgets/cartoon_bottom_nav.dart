import 'package:flutter/material.dart';
import '../cartoon_colors.dart';
import '../cartoon_dimensions.dart';

class CartoonNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const CartoonNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Floating Cartoon Bottom Navigation Bar
class CartoonBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CartoonNavItem> items;

  const CartoonBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 68,
      decoration: BoxDecoration(
        color: CartoonColors.white,
        borderRadius: BorderRadius.circular(CartoonDimensions.navBarRadius),
        border: Border.all(
          color: CartoonColors.ink,
          width: CartoonDimensions.borderWidth,
        ),
        boxShadow: CartoonDimensions.shadow(
          offset: const Offset(0, 4),
          color: CartoonColors.ink,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = currentIndex == index;
          final item = items[index];

          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? CartoonColors.purpleSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(
                        color: CartoonColors.ink,
                        width: CartoonDimensions.borderWidthThin,
                      )
                    : null,
                boxShadow: isSelected
                    ? CartoonDimensions.shadowSmall(offset: const Offset(1.5, 1.5))
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 24,
                    color: CartoonColors.ink,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: CartoonColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
