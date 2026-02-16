import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChLEsB3uBXQP2LTqR-c1WTTNARxDuSpT8',
    appId: '1:996341507163:android:78662022c2c7ff3582cb7e',
    messagingSenderId: '996341507163',
    projectId: 'lyp-innova-app-7a31f',
    storageBucket: 'lyp-innova-app-7a31f.firebasestorage.app',
  );
}