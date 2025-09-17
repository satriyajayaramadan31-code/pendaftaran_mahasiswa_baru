import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Opsi konfigurasi Firebase untuk project kamu.
/// Dibuat manual dari file `google-services.json`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else {
      return android;
    }
  }

  // 🔹 Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyC6wqxzezeoLJB1lCCUnNFnvCiZofpTZTo",
    appId: "1:906029014724:android:ac648159fc82dd54a8f391",
    messagingSenderId: "906029014724",
    projectId: "project-4-22346",
    storageBucket: "project-4-22346.firebasestorage.app",
  );

  // 🔹 Web (jika nanti pakai Firebase Hosting atau Flutter Web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC6wqxzezeoLJB1lCCUnNFnvCiZofpTZTo",
    appId: "1:906029014724:web:ac648159fc82dd54a8f391",
    messagingSenderId: "906029014724",
    projectId: "project-4-22346",
    storageBucket: "project-4-22346.firebasestorage.app",
  );
}
