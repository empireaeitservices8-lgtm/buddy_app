import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/caller_intent_model.dart';

/// Renders the 3D illustrated conversation category card with rich visual assets
class ConversationCategoryCard extends StatelessWidget {
  final CallerIntent intent;
  final bool isSelected;
  final VoidCallback onTap;

  const ConversationCategoryCard({
    super.key,
    required this.intent,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bannerColor = intent.badgeColor;
    final imagePath = _getImageAssetPath(intent);

    return AnimatedScale(
      scale: isSelected ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? bannerColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? bannerColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: bannerColor.withOpacity(0.40),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: 1.0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The 3D Illustrated Card Asset (scaled to bleed edge-to-edge)
                Transform.scale(
                  scale: 1.07,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback elegant card if image is not loaded
                      return Container(
                        color: bannerColor.withOpacity(0.1),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(intent.emoji, style: const TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text(
                                intent.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: bannerColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Top-Left Selection Checkmark Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.elasticOut,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: bannerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _getImageAssetPath(CallerIntent intent) {
    if (intent.imagePath.isNotEmpty) {
      return intent.imagePath;
    }
    switch (intent.id.toLowerCase()) {
      case 'just_talk':
      case 'conversation':
        return 'assets/images/categories/just_talk.png';
      case 'friendly_conversation':
      case 'friendship':
        return 'assets/images/categories/friendly_conversation.png';
      case 'advice':
        return 'assets/images/categories/advice.png';
      case 'career':
      case 'motivation':
        return 'assets/images/categories/career.png';
      case 'travel':
      case 'guidance':
        return 'assets/images/categories/travel.png';
      case 'elder_companion':
      case 'companionship':
        return 'assets/images/categories/elder_companion.png';
      case 'student_companion':
      case 'companion':
        return 'assets/images/categories/student_companion.jpg';
      case 'language':
      case 'listening':
        return 'assets/images/categories/language.png';
      case 'casual':
      case 'human_connection':
      default:
        return 'assets/images/categories/casual.png';
    }
  }
}
