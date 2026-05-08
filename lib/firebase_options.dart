import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCcfPTZn0gMVJnyBA7xPwxFMBwBYCX5cPk',
    authDomain: 'cv-maker-30930.firebaseapp.com',
    projectId: 'cv-maker-30930',
    storageBucket: 'cv-maker-30930.firebasestorage.app',
    messagingSenderId: '427541291405',
    appId: '1:427541291405:web:56fbceb388bf8b31029dc4',
    measurementId: 'G-RMEXVLCV90',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCcfPTZn0gMVJnyBA7xPwxFMBwBYCX5cPk',
    authDomain: 'cv-maker-30930.firebaseapp.com',
    projectId: 'cv-maker-30930',
    storageBucket: 'cv-maker-30930.firebasestorage.app',
    messagingSenderId: '427541291405',
    appId: '1:427541291405:web:56fbceb388bf8b31029dc4',
  );
}
