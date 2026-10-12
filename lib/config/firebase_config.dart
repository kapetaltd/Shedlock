import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project settings, so no google-services.json or Gradle plugin is
/// needed. These identify the app to Firebase; they are not secrets (Firebase
/// ships them inside every app).
///
/// Copy them from android/app/google-services.json (Firebase console →
/// Project settings → Your apps → Shedlock Android):
///   apiKey            ← client[0].api_key[0].current_key
///   appId             ← client[0].client_info.mobilesdk_app_id
///   messagingSenderId ← project_info.project_number
///   projectId         ← project_info.project_id
///   storageBucket     ← project_info.storage_bucket
///
/// While a platform's options are null, analytics events are only printed
/// to the log there.
class FirebaseConfig {
  /// Firebase project "shedlock-b885f" (Kapeta), app com.kapeta.shedlock.
  static const FirebaseOptions? android = FirebaseOptions(
    apiKey: 'AIzaSyD2cn3THBZluxd1kaL8zXKmCsn8_6VnR3k',
    appId: '1:448565260393:android:0fea7d0f5e7ca25d6c72f8',
    messagingSenderId: '448565260393',
    projectId: 'shedlock-b885f',
    storageBucket: 'shedlock-b885f.firebasestorage.app',
  );

  /// Add when Shedlock is registered in Firebase for iOS.
  static const FirebaseOptions? ios = null;

  static FirebaseOptions? get current => switch (defaultTargetPlatform) {
        TargetPlatform.android => android,
        TargetPlatform.iOS => ios,
        _ => null,
      };
}
