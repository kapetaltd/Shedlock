import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/config/monetization_config.dart';

final _appId = RegExp(r'^ca-app-pub-\d{16}~\d{10}$');
final _unitId = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');
const _googleTestPublisher = 'ca-app-pub-3940256099942544';

void main() {
  test('AdMob app IDs are well formed and match the native files', () {
    expect(MonetizationConfig.androidAdMobAppId, matches(_appId));
    expect(MonetizationConfig.iosAdMobAppId, matches(_appId));
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('manifestPlaceholders["admobAppId"] = "${MonetizationConfig.androidAdMobAppId}"'),
    );
    expect(
      File('ios/Runner/Info.plist').readAsStringSync(),
      contains('<string>${MonetizationConfig.iosAdMobAppId}</string>'),
    );
  });

  test('live ad unit IDs, once set, are unit IDs (with /) from the same account', () {
    final android = MonetizationConfig.androidAdMobAppId.split('~').first;
    for (final id in [MonetizationConfig.androidRewardedLive, MonetizationConfig.androidInterstitialLive]) {
      if (id.isEmpty) continue;
      expect(id, matches(_unitId), reason: 'an ad unit ID has a "/", an app ID has a "~"');
      expect(id, startsWith('$android/'));
    }
    for (final id in [MonetizationConfig.iosRewardedLive, MonetizationConfig.iosInterstitialLive]) {
      if (id.isNotEmpty) expect(id, matches(_unitId));
    }
  });

  test('debug builds always use Google test ads; release uses live units when set', () {
    // Tests run in debug mode.
    expect(MonetizationConfig.rewardedUnitId, startsWith('$_googleTestPublisher/'));
    expect(MonetizationConfig.interstitialUnitId, startsWith('$_googleTestPublisher/'));

    const live = 'ca-app-pub-1575340671876931/1111111111';
    const test = '$_googleTestPublisher/2222222222';
    expect(MonetizationConfig.pickUnit(live: live, test: test, release: false), test);
    expect(MonetizationConfig.pickUnit(live: live, test: test, release: true), live);
    expect(MonetizationConfig.pickUnit(live: '', test: test, release: true), test);
  });
}
