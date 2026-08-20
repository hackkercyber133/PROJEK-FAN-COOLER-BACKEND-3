// =====================================================================
// Terisi otomatis dari google-services.json project "fan-cooler-app".
// Kalau kamu bikin ulang app Firebase (misal ganti package name), file
// ini perlu di-update lagi (ganti nilai di bawah dengan yang baru dari
// google-services.json versi baru).
// =====================================================================
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions belum dikonfigurasi untuk web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2pr--LwIte_6juGTCpVBTHrgfn_qf3Zw',
    appId: '1:1004925560885:android:af4cb0d84e1c202927297c',
    messagingSenderId: '1004925560885',
    projectId: 'fan-cooler-app',
    storageBucket: 'fan-cooler-app.firebasestorage.app',
  );
}

