enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

enum AuthFlowMode {
  login,
  signUp,
}

enum RegistrationStep {
  phoneNumber(0),
  otpVerification(1),
  firstDetails(2),
  completed(3);

  final int stepIndex;
  const RegistrationStep(this.stepIndex);

  int get totalSteps => 3;
  double get progress => (stepIndex + 1) / totalSteps;
}


