import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/caller_intent_model.dart';
import '../../../viewmodels/home_view_model.dart';

/// Interactive Neo-brutalist Modal Sheet: "What do you need right now?"
class QuickIntentBottomSheet extends StatefulWidget {
  final HomeViewModel viewModel;

  const QuickIntentBottomSheet({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, HomeViewModel viewModel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickIntentBottomSheet(viewModel: viewModel),
    );
  }

  @override
  State<QuickIntentBottomSheet> createState() => _QuickIntentBottomSheetState();
}

class _QuickIntentBottomSheetState extends State<QuickIntentBottomSheet> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.viewModel.selectedIntentIds);
    if (_selectedIds.isEmpty && widget.viewModel.callerIntents.isNotEmpty) {
      _selectedIds.add(widget.viewModel.callerIntents.first.id);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final intents = widget.viewModel.callerIntents;
    final selectedCount = _selectedIds.length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.strokeBlack, width: 2.5),
          left: BorderSide(color: AppColors.strokeBlack, width: 2.5),
          right: BorderSide(color: AppColors.strokeBlack, width: 2.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.strokeBlack.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                  boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      'WHY DO YOU WANT TO TALK?',
                      style: AppTypography.badgeText.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.strokeBlack),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            'What do you need right now? 💬',
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Select one or more topics to connect with the best listeners.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),

          // 9 Options List with Checkboxes
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.44,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: intents.map((intent) {
                  final isSelected = _selectedIds.contains(intent.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _toggle(intent.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? intent.badgeColor
                              : AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: isSelected ? 2.2 : 1.8,
                          ),
                          boxShadow: isSelected
                              ? AppTheme.neoShadow(offset: const Offset(3, 3))
                              : AppTheme.neoShadow(offset: const Offset(1.5, 1.5)),
                        ),
                        child: Row(
                          children: [
                            // Emoji circle
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.cardWhite
                                    : intent.badgeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.strokeBlack,
                                  width: 1.8,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  intent.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Intent Title & category hint
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    intent.title,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '"${intent.description}"',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Checkbox indicator
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.strokeBlack
                                    : AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.strokeBlack,
                                  width: 2.0,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppColors.cardWhite,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Primary CTA Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: selectedCount == 0
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.viewModel.setMultipleSelectedIntents(_selectedIds);
                      widget.viewModel.submitSelectedIntents();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.strokeBlack,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(
                    color: AppColors.strokeBlack,
                    width: 2.2,
                  ),
                ),
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      selectedCount > 0
                          ? 'Connect for $selectedCount Topic${selectedCount > 1 ? "s" : ""} ✨'
                          : 'Select at least 1 topic',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.strokeBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: AppColors.strokeBlack,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
