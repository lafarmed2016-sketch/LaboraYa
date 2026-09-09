// File generated from google-services.json for project laboraya-produccion
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCh05y0YA_CLYv3kDUcJ2V9u6EBu1xiQII',
    appId: '1:320726381262:android:df25f79b3464803c6d169f',
    messagingSenderId: '320726381262',
    projectId: 'laboraya-produccion',
    storageBucket: 'laboraya-produccion.firebasestorage.app',
  );
}
