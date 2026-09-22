import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/auth_state.dart';
import '../../data/repositories/auth_api_repository.dart';
import '../../data/repositories/user_api_repository.dart';
import '../../viewmodels/registration_view_model.dart';
import '../agent/agent_dashboard_screen.dart';
import '../home/home_dashboard_screen.dart';
import '../widgets/neo_background.dart';
import '../widgets/segmented_progress_bar.dart';
import '../widgets/toast_utils.dart';
import 'otp_verification_screen.dart';
import 'phone_number_screen.dart';
import 'profile_details_screen.dart';

class RegistrationFlowPage extends StatefulWidget {
  final AuthFlowMode initialMode;

  const RegistrationFlowPage({
    super.key,
    this.initialMode = AuthFlowMode.login,
  });

  @override
  State<RegistrationFlowPage> createState() => _RegistrationFlowPageState();
}

class _RegistrationFlowPageState extends State<RegistrationFlowPage> {
  late final RegistrationViewModel _viewModel;
  int _lastStepIndex = 0;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _viewModel = RegistrationViewModel(
      authRepository: AuthApiRepository(),
      userRepository: UserApiRepository(),
      initialMode: widget.initialMode,
    );
    _lastStepIndex = _viewModel.stepIndex;
    _viewModel.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_viewModel.hasError &&
        _viewModel.errorMessage != _lastError &&
        mounted) {
      _lastError = _viewModel.errorMessage;
      showNeoToast(context, _viewModel.errorMessage!, isError: true);
    }
    if (!_viewModel.hasError) {
      _lastError = null;
    }

    if (_viewModel.currentStep == RegistrationStep.completed && mounted) {
      final isAgent = _viewModel.isAgent;
      final targetScreen = isAgent
          ? const AgentDashboardScreen()
          : const HomeDashboardScreen();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetScreen),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleBack() {
    final shouldPop = _viewModel.goBack();
    if (shouldPop && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _handleForwardSwipe() {
    final currentStep = _viewModel.currentStep;
    switch (currentStep) {
      case RegistrationStep.phoneNumber:
        _viewModel.submitPhoneNumber();
        break;
      case RegistrationStep.otpVerification:
        _viewModel.submitOtp();
        break;
      case RegistrationStep.firstDetails:
        _viewModel.submitFirstDetails();
        break;
      case RegistrationStep.completed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final currentStep = _viewModel.currentStep;
        final currentIndex = currentStep.stepIndex;
        final isForward = currentIndex >= _lastStepIndex;
        _lastStepIndex = currentIndex;

        return PopScope(
          canPop: currentStep == RegistrationStep.phoneNumber,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _handleBack();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFBF8EE),
            body: NeoBackground(
              child: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity > 300) {
                      _handleBack();
                    } else if (velocity < -300) {
                      _handleForwardSwipe();
                    }
                  },
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Top Navigation Row
                          if (currentStep != RegistrationStep.phoneNumber)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                top: 8.0,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: _handleBack,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.cardWhite,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.strokeBlack,
                                          width: 1.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.strokeBlack
                                                .withOpacity(0.15),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: AppColors.strokeBlack,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Dynamic step content with smooth slide transition
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (
                                Widget? currentChild,
                                List<Widget> previousChildren,
                              ) {
                                return Stack(
                                  alignment: Alignment.topCenter,
                                  children: <Widget>[
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                );
                              },
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                final inOffset = Tween<Offset>(
                                  begin: Offset(isForward ? 1.0 : -1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(animation);

                                return SlideTransition(
                                  position: inOffset,
                                  child: child,
                                );
                              },
                              child: SizedBox(
                                key: ValueKey(currentStep),
                                width: double.infinity,
                                height: double.infinity,
                                child: _buildCurrentStepView(currentStep),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStepView(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.phoneNumber:
        return PhoneNumberView(viewModel: _viewModel);
      case RegistrationStep.otpVerification:
        return OtpVerificationView(viewModel: _viewModel);
      case RegistrationStep.firstDetails:
        return ProfileDetailsView(viewModel: _viewModel);
      case RegistrationStep.completed:
        return const Center(child: CircularProgressIndicator());
    }
  }
}
