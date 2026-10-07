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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await PrefsStorageService.create();
  final analytics = await _initAnalytics();

  final AdsService ads = _mobile ? AdMobAdsService() : PlaceholderAdsService();
  final IapService iap = _mobile && !_fakeStore
      ? StoreIapService(storage: storage, analytics: analytics)
      : FakeIapService(storage: storage, analytics: analytics);

  await SessionService(storage: storage, analytics: analytics, clock: DateTime.now).start();
  await iap.init();
  final sound = FlameSoundPlayer();
  await sound.preload();

  runApp(ShedlockApp(
    storage: storage,
    ads: ads,
    share: const NativeShareService(),
    analytics: analytics,
    iap: iap,
    sound: sound,
    haptics: const SystemHaptics(),
  ));

  // After the first frame: the consent form (where required) and ad
  // preloading must not delay startup.
  unawaited(ads.init());
}

/// Firebase needs google-services.json / GoogleService-Info.plist (see
/// README). Without them the app runs with analytics printed to the log.
Future<AnalyticsService> _initAnalytics() async {
  if (!_mobile) return const DebugAnalyticsService();
  try {
    await Firebase.initializeApp();
    return FirebaseAnalyticsService(FirebaseAnalytics.instance);
  } on Object catch (e) {
    debugPrint('[analytics] Firebase not configured, events will only be printed: $e');
    return const DebugAnalyticsService();
  }
}
