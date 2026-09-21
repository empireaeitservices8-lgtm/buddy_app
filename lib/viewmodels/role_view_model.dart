import '../data/models/user_role.dart';
import '../data/repositories/auth_repository.dart';
import 'base_view_model.dart';

class RoleSelectionViewModel extends BaseViewModel {
  final IAuthRepository _authRepository;

  UserRole _selectedRole = UserRole.user;

  RoleSelectionViewModel({required IAuthRepository authRepository})
      : _authRepository = authRepository {
    _selectedRole = _authRepository.currentRole ?? UserRole.user;
  }

  UserRole get selectedRole => _selectedRole;
  bool get isUserSelected => _selectedRole == UserRole.user;
  bool get isAgentSelected => _selectedRole == UserRole.agent;

  String get actionButtonText {
    return _selectedRole == UserRole.user ? 'Continue as User' : 'Continue as Agent';
  }

  void selectRole(UserRole role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    notifyListenersSafely();
  }

  Future<bool> confirmRole() async {
    setLoading(true);
    try {
      // Record selected role
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }
}
