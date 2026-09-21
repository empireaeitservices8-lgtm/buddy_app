import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  bool get isDisposed => _isDisposed;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListenersSafely();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListenersSafely();
  }

  void clearError() {
    _errorMessage = null;
    notifyListenersSafely();
  }

  void notifyListenersSafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
