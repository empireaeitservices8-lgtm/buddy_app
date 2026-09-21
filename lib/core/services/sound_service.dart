import 'dart:async';
import 'package:flutter/services.dart';

/// Service for audio/haptic sound effects during calls and interactions.
class SoundService {
  /// Plays a distinctive sequence of alert beeps and haptic vibration pulses
  /// to warn the user that their coin balance has reached the threshold (e.g. 300 coins).
  static Future<void> playLowBalanceBeep() async {
    try {
      // First Beep + Heavy Haptic
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 260));

      // Second Beep + Heavy Haptic
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 260));

      // Third Beep + Vibrating Pulse
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
