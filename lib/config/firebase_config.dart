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
/// While [android] is null, analytics events are only printed to the log.
class FirebaseConfig {
  static const FirebaseOptions? android = null;

  /// Add when Shedlock is registered in Firebase for iOS.
  static const FirebaseOptions? ios = null;

  static FirebaseOptions? get current => switch (defaultTargetPlatform) {
        TargetPlatform.android => android,
        TargetPlatform.iOS => ios,
        _ => null,
      };
}
