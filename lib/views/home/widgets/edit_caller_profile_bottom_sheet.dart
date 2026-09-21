// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/home_view_model.dart';
import '../../widgets/neo_text_field.dart';
import '../../widgets/toast_utils.dart';

class EditCallerProfileBottomSheet extends StatefulWidget {
  final HomeViewModel viewModel;

  const EditCallerProfileBottomSheet({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, HomeViewModel viewModel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditCallerProfileBottomSheet(viewModel: viewModel),
    );
  }

  @override
  State<EditCallerProfileBottomSheet> createState() =>
      _EditCallerProfileBottomSheetState();
}

class _EditCallerProfileBottomSheetState
    extends State<EditCallerProfileBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  late String _selectedLanguage;
  bool _isSaving = false;

  final List<String> _availableLanguages = [
    'Hindi',
    'English',
    'Malayalam',
    'Tamil',
    'Telugu',
    'Kannada',
    'Bengali',
    'Marathi',
    'Gujarati',
    'Punjabi',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.viewModel.userProfile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _ageController = TextEditingController(
      text: profile?.age != null ? profile!.age.toString() : '',
    );

    final currentLang = profile?.language ?? 'Hindi';
    _selectedLanguage = _availableLanguages.firstWhere(
      (l) => l.toLowerCase() == currentLang.toLowerCase(),
      orElse: () => currentLang.isNotEmpty ? currentLang : 'Hindi',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showNeoToast(context, 'Please enter your name', isError: true);
      return;
    }

    final ageText = _ageController.text.trim();
    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age < 10 || age > 99) {
        showNeoToast(context, 'Please enter a valid 2-digit age (10-99)', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);

    final success = await widget.viewModel.updateCallerProfile(
      name: name,
      age: age,
      language: _selectedLanguage,
      interests: const [],
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        showNeoToast(context, 'Profile updated successfully! ✨');
        Navigator.of(context).pop();
      } else {
        showNeoToast(
          context,
          widget.viewModel.errorMessage ?? 'Failed to update profile',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.strokeBlack, width: 2.5),
          left: BorderSide(color: AppColors.strokeBlack, width: 2.5),
          right: BorderSide(color: AppColors.strokeBlack, width: 2.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.strokeBlack.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentLavender,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 1.8,
                          ),
                          boxShadow: AppTheme.neoShadow(
                            offset: const Offset(2, 2),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: AppColors.strokeBlack,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit Profile ✏️',
                        style: AppTypography.headlineLarge.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.8,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(2, 2),
                        ),
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
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1.5, color: AppColors.strokeBlack),

            // Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. NAME FIELD
                    NeoTextField(
                      label: 'YOUR NAME / CALLER NAME',
                      hintText: 'e.g. Alex, Maya',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 18),

                    // 2. AGE FIELD
                    NeoTextField(
                      label: 'AGE',
                      hintText: 'e.g. 24',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. LANGUAGE SELECTION
                    Text(
                      'PRIMARY LANGUAGE 🗣️',
                      style: AppTypography.labelUppercase,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableLanguages.map((lang) {
                        final isSelected =
                            _selectedLanguage.toLowerCase() == lang.toLowerCase();
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedLanguage = lang);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFB8C4FE)
                                  : AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 1.8,
                              ),
                              boxShadow: isSelected
                                  ? AppTheme.neoShadow(
                                      offset: const Offset(2, 2),
                                    )
                                  : null,
                            ),
                            child: Text(
                              lang,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: AppColors.textBlack,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Save CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.backgroundCream,
                border: Border(
                  top: BorderSide(color: AppColors.strokeBlack, width: 1.5),
                ),
              ),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveProfile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.buttonDark,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.2,
                    ),
                    boxShadow: AppTheme.neoShadow(
                      offset: const Offset(3.5, 3.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.buttonTextLight,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Profile Changes ✨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.buttonTextLight,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
