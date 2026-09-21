// File generated/configured for Firebase options based on google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [DefaultFirebaseOptions] enables Firebase to initialize with the appropriate
/// credentials for the current platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return android;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsG0I4WrrNjVRQI1f3EXUe4XPurJ1R8mY',
    appId: '1:109214702554:android:f51c1a8efa8b1982a57ee3',
    messagingSenderId: '109214702554',
    projectId: 'gabby-talk-b9722',
    storageBucket: 'gabby-talk-b9722.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAsG0I4WrrNjVRQI1f3EXUe4XPurJ1R8mY',
    appId: '1:109214702554:android:f51c1a8efa8b1982a57ee3',
    messagingSenderId: '109214702554',
    projectId: 'gabby-talk-b9722',
    storageBucket: 'gabby-talk-b9722.firebasestorage.app',
  );
}
