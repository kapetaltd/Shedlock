import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/ads_service.dart';
import 'services/analytics_service.dart';
import 'services/feedback_service.dart';
import 'services/iap_service.dart';
import 'services/session_service.dart';
import 'services/share_service.dart';
import 'services/storage_service.dart';

/// `--dart-define=FAKE_STORE=true` swaps in a pretend store so the shop can
/// be tried before products exist in Play Console / App Store Connect.
const _fakeStore = bool.fromEnvironment('FAKE_STORE');

bool get _mobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only fast, local work happens before the first frame. Anything that
  // talks to Google Play, Firebase or the audio system runs after runApp,
  // with a timeout, so a slow or missing service (an emulator without the
  // Play Store, no network, a stuck billing connection) can never leave
  // the app on its splash screen.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await PrefsStorageService.create();
  final analytics = await _initAnalytics();

  final AdsService ads = _mobile ? AdMobAdsService() : PlaceholderAdsService();
  final IapService iap = _mobile && !_fakeStore
      ? StoreIapService(storage: storage, analytics: analytics)
      : FakeIapService(storage: storage, analytics: analytics);
  final sound = FlameSoundPlayer();

  runApp(
    ShedlockApp(
      storage: storage,
      ads: ads,
      share: const NativeShareService(),
      analytics: analytics,
      iap: iap,
      sound: sound,
      haptics: const SystemHaptics(),
    ),
  );

  unawaited(
    _background(
      'session',
      SessionService(storage: storage, analytics: analytics, clock: DateTime.now).start(),
    ),
  );
  unawaited(_background('store', iap.init()));
  unawaited(_background('sound', sound.preload()));
  // The consent form (where required) and ad preloading.
  unawaited(_background('ads', ads.init()));
}

/// Runs a start-up task without blocking the app; logs failures and hangs.
Future<void> _background(String name, Future<void> task) async {
  try {
    await task.timeout(const Duration(seconds: 20));
  } on Object catch (e) {
    debugPrint('[startup] $name did not finish: $e');
  }
}

/// Firebase needs google-services.json / GoogleService-Info.plist (see
/// README). Without them the app runs with analytics printed to the log.
Future<AnalyticsService> _initAnalytics() async {
  if (!_mobile) return const DebugAnalyticsService();
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    return FirebaseAnalyticsService(FirebaseAnalytics.instance);
  } on Object catch (e) {
    debugPrint('[analytics] Firebase not configured, events will only be printed: $e');
    return const DebugAnalyticsService();
  }
}
