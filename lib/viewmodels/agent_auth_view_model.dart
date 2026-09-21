import '../data/repositories/auth_repository.dart';
import 'base_view_model.dart';

class AgentAuthViewModel extends BaseViewModel {
  final IAuthRepository _authRepository;

  String _username = '';
  String _password = '';
  bool _obscurePassword = true;

  AgentAuthViewModel({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  String get username => _username;
  String get password => _password;
  bool get obscurePassword => _obscurePassword;

  void setUsername(String value) {
    _username = value;
    clearError();
    notifyListenersSafely();
  }

  void setPassword(String value) {
    _password = value;
    clearError();
    notifyListenersSafely();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListenersSafely();
  }

  bool get isValid => _username.trim().isNotEmpty && _password.trim().isNotEmpty;

  Future<bool> login() async {
    if (!isValid) {
      setError('Please enter username and password');
      return false;
    }

    setLoading(true);
    clearError();
    try {
      final success = await _authRepository.agentLogin(
        username: _username.trim(),
        password: _password,
      );
      if (success) {
        return true;
      } else {
        setError('Invalid agent credentials. Try again.');
        return false;
      }
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^[A-Za-z0-9_]*Exception:\s*'), '');
      setError(msg);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
