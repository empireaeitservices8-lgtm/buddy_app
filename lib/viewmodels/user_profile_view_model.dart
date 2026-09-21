import 'dart:io';
import '../core/network/api_exceptions.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_api_repository.dart';
import '../data/repositories/user_repository.dart';
import 'base_view_model.dart';

/// ViewModel demonstrating clean architecture, API state management,
/// field-level validation errors, and reactive UI state updates.
class UserProfileViewModel extends BaseViewModel {
  final IUserRepository _userRepository;

  UserProfile? _userProfile;
  Map<String, dynamic>? _fieldValidationErrors;
  bool _isUploadingAvatar = false;
  final double _uploadProgress = 0.0;

  UserProfileViewModel({IUserRepository? userRepository})
    : _userRepository = userRepository ?? UserApiRepository();

  // Getters
  UserProfile? get userProfile => _userProfile;
  Map<String, dynamic>? get fieldValidationErrors => _fieldValidationErrors;
  bool get isUploadingAvatar => _isUploadingAvatar;
  double get uploadProgress => _uploadProgress;

  /// Loads the profile from the remote API endpoint.
  Future<void> fetchProfile() async {
    setLoading(true);
    clearError();
    _fieldValidationErrors = null;

    try {
      _userProfile = await _userRepository.getProfile();
    } on NetworkException catch (e) {
      setError(e.message);
    } on UnauthorizedException catch (e) {
      setError(e.message);
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('An unexpected error occurred while loading profile.');
    } finally {
      setLoading(false);
    }
  }

  /// Updates profile details and handles [ValidationException] with field level error maps.
  Future<bool> updateProfile({
    required String firstName,
    String? lastName,
    String? email,
    String? bio,
    int? age,
    Gender? gender,
  }) async {
    if (_userProfile == null) return false;

    setLoading(true);
    clearError();
    _fieldValidationErrors = null;

    final updated = _userProfile!.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      bio: bio,
      age: age,
      gender: gender,
    );

    try {
      _userProfile = await _userRepository.updateProfile(updated);
      notifyListenersSafely();
      return true;
    } on ValidationException catch (e) {
      _fieldValidationErrors = e.errors;
      setError(e.message);
      return false;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to update profile. Please try again.');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Uploads user profile picture avatar
  Future<bool> uploadAvatar(File imageFile) async {
    _isUploadingAvatar = true;
    clearError();
    notifyListenersSafely();

    try {
      final avatarUrl = await _userRepository.uploadAvatar(imageFile);
      if (avatarUrl.isNotEmpty && _userProfile != null) {
        _userProfile = _userProfile!.copyWith(avatarUrl: avatarUrl);
      }
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Avatar upload failed: $e');
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListenersSafely();
    }
  }

  /// Updates interest list on remote server
  Future<bool> saveInterests(List<String> interests) async {
    setLoading(true);
    clearError();

    try {
      final updatedInterests = await _userRepository.updateInterests(interests);
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(interests: updatedInterests);
      }
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to save interests.');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Helper to get a specific field's validation error message for UI text fields
  String? getFieldError(String fieldName) {
    if (_fieldValidationErrors == null) return null;
    final val = _fieldValidationErrors![fieldName];
    if (val is List && val.isNotEmpty) {
      return val.first.toString();
    }
    return val?.toString();
  }
}
