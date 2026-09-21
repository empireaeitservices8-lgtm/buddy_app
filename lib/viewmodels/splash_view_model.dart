import 'base_view_model.dart';

class SplashViewModel extends BaseViewModel {
  double _dragProgress = 0.0;
  bool _isUnlocked = false;

  double get dragProgress => _dragProgress;
  bool get isUnlocked => _isUnlocked;

  void updateDragProgress(double progress) {
    if (_isUnlocked) return;
    _dragProgress = progress.clamp(0.0, 1.0);
    if (_dragProgress >= 0.95) {
      _isUnlocked = true;
      _dragProgress = 1.0;
    }
    notifyListenersSafely();
  }

  void resetDrag() {
    _dragProgress = 0.0;
    _isUnlocked = false;
    notifyListenersSafely();
  }
}
