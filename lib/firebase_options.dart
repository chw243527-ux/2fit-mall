// firebase_options.dart
// fit-mall Firebase 프로젝트 실제 설정
// project_id   : fit-mall
// project_number: 187081765755

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not supported.');
      default:
        throw UnsupportedError('Unknown platform.');
    }
  }

  // ── 웹 ─────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCxdgTXMk08bGxrUiHpmLBqvcVsPXCm54w',
    appId: '1:187081765755:web:e1d58f9cfee0aa0b5d03de',
    messagingSenderId: '187081765755',
    projectId: 'fit-mall',
    authDomain: 'fit-mall.firebaseapp.com',
    storageBucket: 'fit-mall.firebasestorage.app',
    measurementId: 'G-JS79F5C56P',
  );

  // ── Android ────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDu72VZ2IlUI8gxWROsfPJFuC1qORCdkAE',
    appId: '1:187081765755:android:90a8ccb9af4b91515d03de',
    messagingSenderId: '187081765755',
    projectId: 'fit-mall',
    storageBucket: 'fit-mall.firebasestorage.app',
  );

  // ── iOS ────────────────────────────────────────────────────
  // iOS 앱을 Firebase Console에 등록 후 GoogleService-Info.plist 값으로 교체
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCxdgTXMk08bGxrUiHpmLBqvcVsPXCm54w',
    appId: '1:187081765755:ios:0000000000000000',
    messagingSenderId: '187081765755',
    projectId: 'fit-mall',
    storageBucket: 'fit-mall.firebasestorage.app',
    iosBundleId: 'com.twofit.twofitMall',
  );

  // ── macOS ──────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCxdgTXMk08bGxrUiHpmLBqvcVsPXCm54w',
    appId: '1:187081765755:ios:0000000000000000',
    messagingSenderId: '187081765755',
    projectId: 'fit-mall',
    storageBucket: 'fit-mall.firebasestorage.app',
    iosBundleId: 'com.twofit.twofitMall',
  );

  // ── Windows ────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCxdgTXMk08bGxrUiHpmLBqvcVsPXCm54w',
    appId: '1:187081765755:web:e1d58f9cfee0aa0b5d03de',
    messagingSenderId: '187081765755',
    projectId: 'fit-mall',
    authDomain: 'fit-mall.firebaseapp.com',
    storageBucket: 'fit-mall.firebasestorage.app',
    measurementId: 'G-JS79F5C56P',
  );
}
