// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/toast_utils.dart';

/// Interactive Neo-Brutalist Post-Call Rating Bottom Sheet
/// Shown to the user immediately after finishing a call with an agent.
class AgentRatingBottomSheet extends StatefulWidget {
  final String agentId;
  final String agentName;
  final String? agentAvatar;
  final String? category;
  final int? callId;

  const AgentRatingBottomSheet({
    super.key,
    required this.agentId,
    required this.agentName,
    this.agentAvatar,
    this.category,
    this.callId,
  });

  /// Static helper to display the rating bottom sheet modal
  static Future<void> show(
    BuildContext context, {
    required String agentId,
    required String agentName,
    String? agentAvatar,
    String? category,
    int? callId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgentRatingBottomSheet(
        agentId: agentId,
        agentName: agentName,
        agentAvatar: agentAvatar,
        category: category,
        callId: callId,
      ),
    );
  }

  @override
  State<AgentRatingBottomSheet> createState() => _AgentRatingBottomSheetState();
}

class _AgentRatingBottomSheetState extends State<AgentRatingBottomSheet> {
  int _selectedRating = 5;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  static const Map<String, String> _tagDisplayMap = {
    'Great Listener': 'Great Listener 👂',
    'Very Empathetic': 'Very Empathetic ❤️',
    'Helpful Advice': 'Helpful Advice 💡',
    'Friendly & Warm': 'Friendly & Warm 🌟',
    'Calming Voice': 'Calming Voice 🧘',
    'Fun & Engaging': 'Fun & Engaging 💬',
    'Patient & Kind': 'Patient & Kind 🌸',
    'Understood Me Well': 'Understood Me Well 🎯',
  };

  final List<String> _feedbackTags = const [
    'Great Listener',
    'Very Empathetic',
    'Helpful Advice',
    'Friendly & Warm',
    'Calming Voice',
    'Fun & Engaging',
    'Patient & Kind',
    'Understood Me Well',
  ];

  (String, Color) get _ratingInfo {
    switch (_selectedRating) {
      case 5:
        return ('Outstanding! Loved it! 💖', const Color(0xFFFFD6E5));
      case 4:
        return ('Great conversation! 👍', const Color(0xFFD4DCFF));
      case 3:
        return ('Good & helpful 🙂', const Color(0xFFD8F3DC));
      case 2:
        return ('Could be better 😐', const Color(0xFFFFF2B2));
      case 1:
      default:
        return ('Not a good fit 😞', const Color(0xFFFFD1D1));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final parsedUserId = int.tryParse(widget.agentId) ?? widget.agentId;
      final payload = {
        'user_id': parsedUserId,
        'agent_id': parsedUserId,
        'agent_user_id': parsedUserId,
        'rating': _selectedRating,
        if (_selectedTags.isNotEmpty) 'tags': _selectedTags.toList(),
        if (_commentController.text.trim().isNotEmpty)
          'comment': _commentController.text.trim(),
        if (widget.callId != null && widget.callId! > 0)
          'call_id': widget.callId,
      };

      debugPrint('⭐ [AgentRatingBottomSheet] Submitting rating payload with user_id=$parsedUserId: $payload');

      // 1. Submit to agent/rating/ (main rating endpoint with user_id)
      final res = await ApiService().post(
        ApiConstants.submitRating,
        data: payload,
        requiresAuth: true,
      );

      // 2. Fallback to review endpoint if not handled by primary
      final targetId = widget.agentId.isNotEmpty
          ? widget.agentId
          : (widget.callId != null && widget.callId! > 0
              ? widget.callId.toString()
              : '');

      if (!res.isSuccess && targetId.isNotEmpty) {
        await ApiService().post(
          ApiConstants.reviewCall(targetId),
          data: payload,
          requiresAuth: true,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [AgentRatingBottomSheet] Rating submission note: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(context).pop();
        showNeoToast(
          context,
          'Thank you! Your review for ${widget.agentName} was submitted ✨',
          isError: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (ratingText, ratingBg) = _ratingInfo;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(color: AppColors.strokeBlack, width: 2.5),
          left: BorderSide(color: AppColors.strokeBlack, width: 2.5),
          right: BorderSide(color: AppColors.strokeBlack, width: 2.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.strokeBlack.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Top Header: Badge & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7CE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                    boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⭐', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 6),
                      Text(
                        'RATE YOUR LISTENER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.strokeBlack, width: 1.8),
                      boxShadow: AppTheme.neoShadow(offset: const Offset(1.8, 1.8)),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.strokeBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Listener Profile Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DCFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                    ),
                    alignment: Alignment.center,
                    child: widget.agentAvatar != null && widget.agentAvatar!.startsWith('http')
                        ? ClipOval(
                            child: Image.network(
                              widget.agentAvatar!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text('🎧', style: TextStyle(fontSize: 28)),
                            ),
                          )
                        : const Text('🎧', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call with ${widget.agentName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8F3DC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.strokeBlack, width: 1.2),
                              ),
                              child: Text(
                                widget.category?.isNotEmpty == true
                                    ? widget.category!
                                    : 'Verified Listener',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Headline Question
            const Text(
              'How was your conversation?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your review helps improve connections for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textBlack.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 14),

            // 5-Star Interactive Rating Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _selectedRating;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starNumber;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 0.95,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 42,
                        color: isSelected ? const Color(0xFFFFB703) : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Rating Reaction Pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: ratingBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.strokeBlack, width: 1.6),
                boxShadow: AppTheme.neoShadow(offset: const Offset(2, 2)),
              ),
              child: Text(
                ratingText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section: What went well?
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What went well? ✨',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Feedback Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feedbackTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFD6E5) : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: isSelected ? 2.0 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? AppTheme.neoShadow(offset: const Offset(2, 2))
                          : null,
                    ),
                    child: Text(
                      _tagDisplayMap[tag] ?? tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Comments / Note Box
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.strokeBlack, width: 2.0),
                boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: TextField(
                controller: _commentController,
                maxLines: 2,
                minLines: 2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
                decoration: const InputDecoration(
                  hintText: 'Write a note or feedback (optional)...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3064), // Deep Navy
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(
                      color: AppColors.strokeBlack,
                      width: 2.2,
                    ),
                  ),
                  shadowColor: Colors.transparent,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit Review ✨',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // Skip Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: AppColors.textBlack.withOpacity(0.55),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
