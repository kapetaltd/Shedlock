# Shedlock

*Shed your tail. Lock your prey.*

A modern take on Snake for Android and iOS, built with Flutter + Flame.
Shed your tail to leave temporary walls, trap fleeing "runner" food to lock it
for a bonus, rewind three seconds when you crash, and play the same daily board
as everyone else. Clean, minimal look by default (light or dark, following the
device), with a full retro LCD look available as a cosmetic theme.

See [docs/PLAN.md](docs/PLAN.md) for architecture notes and the decisions made
in each phase.

---

## Contents
1. [Setup](#setup)
2. [Running](#running)
3. [Tests](#tests)
4. [Project layout](#project-layout)
5. [Ads, purchases and analytics](#ads-purchases-and-analytics)
6. [Changing the bundle ID](#changing-the-bundle-id)
7. [Building a release APK / AAB](#building-a-release-apk--aab)
8. [iOS release](#ios-release)
9. [Regenerating assets](#regenerating-assets)
10. [Themes](#themes)
11. [Release checklist](#release-checklist)

---

## Setup

Requirements:
- Flutter stable **3.47+** (Dart 3.13+): `flutter --version`
- Android: Android Studio (or the command-line tools) with an SDK and an
  emulator or device. JDK 17.
- iOS (optional): Xcode and CocoaPods on macOS.

```sh
git clone <this repo> && cd Shedlock
flutter pub get
flutter doctor            # fix anything it flags for Android
```

## Running

```sh
flutter emulators --launch <id>     # or plug in a device
flutter run                         # debug build
flutter run --release               # closer to what players get
flutter run --dart-define=FAKE_STORE=true   # try the shop with a pretend store
flutter run -d chrome               # quick look in a browser (no ads/IAP)
```

Controls: swipe anywhere to turn, tap anywhere to shed. With a keyboard
(emulator or browser): arrows/WASD to turn, Space to shed, P to pause.

## Tests

```sh
flutter analyze
flutter test                                   # everything (Dart VM)
flutter test test/core                         # just the pure game logic
flutter test --platform chrome test/core/seed_determinism_test.dart
                                               # same daily seed under JavaScript
```

The core tests cover movement and collision, shedding and wall fading,
runner lock detection, rewind snapshots, daily seed determinism (same date →
identical game), streaks, share text, ad pacing rules and analytics events.

## Project layout

```
lib/
  core/       Pure Dart game logic: no Flutter/Flame imports (enforced by a test).
              engine/ model/ rng/ rewind/ loop/ run/ daily/ monetization/ analytics/
  game/       Flame game, board/effects rendering, input, palette (all themes), skins
  ui/         Screens (splash, home, daily, game, result, shop, settings), widgets,
              theme/app_theme.dart (text roles and fonts per look)
  services/   Storage, ads, IAP, analytics, sessions, sound/haptics, share
  config/     app_config.dart (name, tagline, daily epoch)
              monetization_config.dart (ALL ad unit + product IDs)
assets/       Fonts (Nunito, Press Start 2P; both OFL), generated sound effects, icon sources
tool/         gen_sfx.dart (sounds), render_icon_test.dart (icon + splash)
test/         core/, game/, services/, ui/
```

## Ads, purchases and analytics

All ad unit IDs and store product IDs are in
[`lib/config/monetization_config.dart`](lib/config/monetization_config.dart).
Development builds always use Google's official **test** ad IDs (see below).

### AdMob IDs
Shedlock uses Kapeta's AdMob account. **Debug and profile builds always use
Google's test ads**, so nobody can tap a real ad while developing (that can get
an AdMob account banned). **Release builds** use the live units, once they are
filled in; an empty live ID falls back to the test unit.

1. The ad unit IDs (with a `/`) go in `MonetizationConfig`:
   `androidRewardedLive`, `androidInterstitialLive`, `iosRewardedLive`,
   `iosInterstitialLive`.
2. The **app** IDs (with a `~`) go in `MonetizationConfig` *and* the native
   files, because the SDK reads them before any Dart code runs:
   - `android/app/build.gradle.kts` → `manifestPlaceholders["admobAppId"]`
     (set: `ca-app-pub-1575340671876931~5932306262`)
   - `ios/Runner/Info.plist` → `GADApplicationIdentifier` (still Google's test
     app ID until Shedlock is added to AdMob for iOS)

   `test/services/ad_config_test.dart` checks the copies match and that unit
   IDs aren't app IDs.
3. In AdMob → Privacy & messaging, create a GDPR consent message. The app runs
   Google's UMP consent flow at startup, and Settings shows **Privacy options**
   wherever the law requires it.
4. Never tap ads in a release build on your own device.

### In-app products
Create these **non-consumable** products in Play Console (Monetize → Products
→ In-app products) and App Store Connect, using the IDs from
`MonetizationConfig.productIds`:

| Pack | Product ID | Contents |
|---|---|---|
| Remove Ads | `shedlock_remove_ads` | No interstitials (rewarded ads stay optional) |
| Skin pack | `shedlock_pack_skins` | Striped, spotted, outline snakes |
| Trail pack | `shedlock_pack_trails` | Ghost and sparkle trails |
| Theme pack | `shedlock_pack_themes` | Sage, Sand, Ink, and the Retro LCD look (Lime, Amber, Ice, Mono, Night) |

Until they exist (and on Android, until a build is uploaded to a test track)
the shop shows N/A. Use `--dart-define=FAKE_STORE=true` to try the flow
before then. Purchases are not validated on a server; that is acceptable for
cosmetics and Remove Ads.

### Ad rules
Interstitials appear only between runs: at most one every 3 finished runs,
never in a player's first 2 sessions, never straight after the daily share
screen, and never for Remove Ads owners. Rewarded ads (extra rewind,
continue) are always player-initiated. A ranked daily offers no ads at all.
The rules are in `lib/core/monetization/ad_policy.dart` and the numbers are in
`MonetizationConfig`.

### Firebase Analytics
1. Create a Firebase project (Kapeta account) with Google Analytics enabled,
   and add an Android app with package `com.kapeta.shedlock` (and an iOS app
   with bundle ID `com.kapeta.shedlock` when needed).
2. Copy the five values from the downloaded `google-services.json` into
   `lib/config/firebase_config.dart` (the file says which field is which).
   No Gradle plugin or config file is needed in the build;
   `google-services.json` is git-ignored.

Until those values are filled in the app still runs, and events are printed to the debug
log. Events logged: `game_session_start`, `run_start`, `run_end`,
`daily_shared`, `ad_shown`, `ad_rewarded`, `iap_purchase`, `streak_length`
(see `lib/core/analytics/events.dart`). `game_session_start` is used because
Firebase reserves `session_start`. For D1/D7 retention use Firebase's built-in
retention report, or cohorts on `game_session_start`.

## Changing the bundle ID

The app ID is `com.kapeta.shedlock` on both platforms (it replaced the
`com.example.shedlock` placeholder). Google Play never lets it change after the
first upload. If you ever need a different one before then, for example
`com.yourstudio.shedlock`:

**Android**
1. `android/app/build.gradle.kts`: set both `namespace` and `applicationId`.
2. Move `android/app/src/main/kotlin/com/kapeta/shedlock/MainActivity.kt` to
   the matching folder (`.../com/yourstudio/shedlock/`) and change its
   `package` line.
3. If Firebase is set up, re-download `google-services.json` for the new ID.

**iOS**
1. In Xcode, Runner target → Signing & Capabilities → Bundle Identifier, or
   replace `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`
   (one entry per build configuration for Runner and RunnerTests).
2. Re-download `GoogleService-Info.plist` if using Firebase.

Then `flutter clean && flutter pub get`. The ID cannot change after the first
Play Store upload, so pick it before release.

## Building a release APK / AAB

1. **Create an upload keystore** (once; keep it safe and backed up):
   ```sh
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
2. **Create `android/key.properties`** (git-ignored, never commit it):
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
   `android/app/build.gradle.kts` picks this up automatically. Without it,
   release builds are signed with the debug key (fine for testing, but Play
   Console rejects them).
3. **Set the version** in `pubspec.yaml` (`version: 1.0.0+1`: name+code; bump
   the code for every upload).
4. **Build:**
   ```sh
   flutter build appbundle --release      # → build/app/outputs/bundle/release/app-release.aab (Play Store)
   flutter build apk --release            # → build/app/outputs/flutter-apk/app-release.apk (sideload/testing)
   flutter build apk --release --split-per-abi   # smaller per-ABI APKs
   ```
5. **Install the APK on a device:**
   `adb install build/app/outputs/flutter-apk/app-release.apk`.
6. **Upload the AAB** to a Play Console internal testing track first. This is
   also needed before in-app products can be tested.

## iOS release

```sh
cd ios && pod install && cd ..
flutter build ipa --release
```
Then open `build/ios/archive/Runner.xcarchive` in Xcode → Distribute App, or
use Transporter with the `.ipa`. Set your team under Signing & Capabilities
first.

## Regenerating assets

```sh
dart run tool/gen_sfx.dart                 # sounds → assets/audio/*.wav (original, synthesised)
flutter test tool/render_icon_test.dart    # icon + splash PNGs from the in-app logo painter
dart run flutter_launcher_icons            # → Android mipmaps + iOS AppIcon
dart run flutter_native_splash:create      # → native launch screens (light + dark)
```

Store listing graphics (icon, feature graphic, captioned screenshots) and the
listing text are in [`docs/store/`](docs/store/listing.md). To regenerate the
graphics from the current app:
```sh
flutter test tool/store_assets_test.dart   # raw screens → build/store/raw
python3 tool/store_assets.py               # framed PNGs → build/store (then copy to docs/store)
```

The logo is drawn by `LogoMarkPainter` in `lib/ui/widgets/logo_art.dart` (the
retro pixel version is in the same file). Edit it there and regenerate, so the
in-app logo and the app icon stay identical.

## Themes

All colours live in `lib/game/palette.dart`, one `Look` per `AppTheme`.
Text styles live in `lib/ui/theme/app_theme.dart` (`TextRole`). To add a
theme, add a `AppTheme` value (with its pack, or `null` for free) and its
`Look`; the shop picks it up automatically. Themes marked `retro: true` use the
pixel style for the whole app.

## Release checklist

- [x] `AppConfig.dailyEpoch` set to launch day: 1 November 2026 (Daily #1). Earlier days show as "Preview".
- [x] AdMob Android: app ID and live ad units set.
- [ ] AdMob iOS IDs (if launching on iOS); GDPR consent message in AdMob.
- [ ] IAP products created in both stores; shop tested on a test track.
- [x] Firebase Android values in `lib/config/firebase_config.dart` (iOS later).
- [x] Bundle ID set: `com.kapeta.shedlock`.
- [ ] Upload keystore + `android/key.properties`; version bumped.
- [x] Privacy policy: https://www.kapetalabs.com/shedlock/privacy (linked in Settings).
- [ ] Privacy policy URL entered in Play Console and AdMob, and the
      Play "Data safety" / App Store privacy forms. The app uses advertising
      ID, analytics and purchase history.
- [ ] Content rating questionnaire. Ads are shown, so declare "contains ads".
- [ ] `flutter analyze && flutter test` green.

## Licences

- Code: yours.
- Fonts, both under the SIL Open Font License 1.1:
  - Nunito, © The Nunito Project Authors
    ([assets/fonts/Nunito-OFL.txt](assets/fonts/Nunito-OFL.txt));
  - Press Start 2P, © The Press Start 2P Project Authors
    ([assets/fonts/PressStart2P-OFL.txt](assets/fonts/PressStart2P-OFL.txt)).
- Sound effects, logo and pixel art: original, generated by the scripts in `tool/`.
