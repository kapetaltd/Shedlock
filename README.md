# Shedlock

*Shed your tail. Lock your prey.*

A modern take on Snake, built with Flutter + Flame. See [docs/PLAN.md](docs/PLAN.md)
for the architecture and roadmap. Full setup and release instructions land in Phase 6.

## Quick start

Requires Flutter stable (3.47+).

```sh
flutter pub get
flutter run                       # on a connected Android device or emulator
flutter run -d chrome             # quick check in a browser
```

Controls: swipe anywhere to turn, tap anywhere to shed. In a browser or
emulator with a keyboard: arrows/WASD to turn, Space to shed, P to pause.

## Tests

```sh
flutter test                      # all tests (Dart VM)
flutter test --platform chrome \
  test/core/seed_determinism_test.dart   # same tests compiled to JS
```

## Ads, purchases and analytics

All ad unit IDs and store product IDs are in
[`lib/config/monetization_config.dart`](lib/config/monetization_config.dart).
They are Google's official **test** IDs. Before release:

1. **AdMob**: replace the rewarded and interstitial unit IDs in that file,
   and the AdMob *app* IDs in `android/app/build.gradle.kts`
   (`manifestPlaceholders["admobAppId"]`) and `ios/Runner/Info.plist`
   (`GADApplicationIdentifier`). The SDK reads the app ID before Dart runs,
   so it has to live in those native files. Set up the consent message
   (GDPR) in AdMob → Privacy & messaging; the app already runs Google's UMP
   consent flow at startup.
2. **Store products**: create four non-consumable products with the IDs in
   `MonetizationConfig.productIds` (Remove Ads, Skin/Trail/Theme packs) in
   Play Console and App Store Connect. Until they exist the shop shows N/A.
   To try the shop before that, run with
   `flutter run --dart-define=FAKE_STORE=true`, which uses a pretend store
   where every purchase succeeds.
3. **Firebase Analytics**: create a Firebase project, add the Android and iOS
   apps, then put `google-services.json` in `android/app/` and
   `GoogleService-Info.plist` in `ios/Runner/`. On Android also apply the
   `com.google.gms.google-services` Gradle plugin. Without these files the
   app still runs, and events are printed to the debug log instead.

Ad rules (`InterstitialPolicy`): interstitials only between runs, at most one
every 3 finished runs, never in a player's first 2 sessions, never straight
after the daily share screen, and never for Remove Ads owners. Rewarded ads
(extra rewind, continue) are always optional and player-initiated.
