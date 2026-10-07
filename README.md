# Shedlock

*Shed your tail. Lock your prey.*

A modern take on Snake for Android and iOS, built with Flutter + Flame.
Shed your tail to leave temporary walls, trap fleeing "runner" food to lock it
for a bonus, rewind three seconds when you crash, and play the same daily board
as everyone else.

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
10. [Release checklist](#release-checklist)

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
  game/       Flame game, board/effects rendering, input, LCD palette, skins
  ui/         Screens (splash, home, daily, game, result, shop, settings), widgets
  services/   Storage, ads, IAP, analytics, sessions, sound/haptics, share
  config/     app_config.dart (name, tagline, daily epoch)
              monetization_config.dart (ALL ad unit + product IDs)
assets/       Pixel font (OFL), generated sound effects, icon sources
tool/         gen_sfx.dart (sounds), gen_icon.py (icon + splash)
test/         core/, game/, services/, ui/
```

## Ads, purchases and analytics

All ad unit IDs and store product IDs are in
[`lib/config/monetization_config.dart`](lib/config/monetization_config.dart).
They are currently Google's official **test** IDs.

### Swapping in real AdMob IDs
1. In AdMob, create the app (Android and iOS) and two ad units per platform:
   **Rewarded** and **Interstitial**.
2. Put the unit IDs in `MonetizationConfig` (`_androidRewarded`,
   `_iosRewarded`, `_androidInterstitial`, `_iosInterstitial`).
3. Put the **app** IDs (the ones with `~`) in:
   - `android/app/build.gradle.kts` → `manifestPlaceholders["admobAppId"]`
   - `ios/Runner/Info.plist` → `GADApplicationIdentifier`

   Also update the reference copies in `MonetizationConfig`. The SDK reads the
   app ID before any Dart code runs, so it has to be in these native files.
4. In AdMob → Privacy & messaging, create a GDPR consent message. The app runs
   Google's UMP consent flow at startup, and Settings shows **Privacy options**
   wherever the law requires it.
5. Keep test IDs (or register test devices) during development. Clicking your
   own live ads can get the account suspended.

### In-app products
Create these **non-consumable** products in Play Console (Monetize → Products
→ In-app products) and App Store Connect, using the IDs from
`MonetizationConfig.productIds`:

| Pack | Product ID | Contents |
|---|---|---|
| Remove Ads | `shedlock_remove_ads` | No interstitials (rewarded ads stay optional) |
| Skin pack | `shedlock_pack_skins` | Striped, dotted, hollow snakes |
| Trail pack | `shedlock_pack_trails` | Ghost and pixel-dust trails |
| Theme pack | `shedlock_pack_themes` | Amber, ice, mono, night screens |

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
1. Create a Firebase project and add an Android app (package
   `com.example.shedlock`, or your new ID) and an iOS app.
2. Download `google-services.json` → `android/app/` and
   `GoogleService-Info.plist` → `ios/Runner/` (add it to the Runner target in
   Xcode).
3. Android: add the Google Services Gradle plugin:
   - `android/settings.gradle.kts`, inside `plugins {}`:
     `id("com.google.gms.google-services") version "<latest 4.x>" apply false`
   - `android/app/build.gradle.kts`, inside `plugins {}`:
     `id("com.google.gms.google-services")`

   (Alternatively run `flutterfire configure`.)

Without these files the app still runs, and events are printed to the debug
log. Events logged: `game_session_start`, `run_start`, `run_end`,
`daily_shared`, `ad_shown`, `ad_rewarded`, `iap_purchase`, `streak_length`
(see `lib/core/analytics/events.dart`). `game_session_start` is used because
Firebase reserves `session_start`. For D1/D7 retention use Firebase's built-in
retention report, or cohorts on `game_session_start`.

## Changing the bundle ID

The placeholder is `com.example.shedlock`. To change it to, for example,
`com.yourstudio.shedlock`:

**Android**
1. `android/app/build.gradle.kts`: set both `namespace` and `applicationId`.
2. Move `android/app/src/main/kotlin/com/example/shedlock/MainActivity.kt` to
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
python3 tool/gen_icon.py                   # icon + splash from the logo pixel art (needs Pillow)
dart run flutter_launcher_icons            # → Android mipmaps + iOS AppIcon
dart run flutter_native_splash:create      # → native launch screens
```

The logo pixel art lives in `lib/ui/widgets/logo_art.dart`. Edit it there and
regenerate, so the in-app logo and the app icon stay identical.

## Release checklist

- [ ] `AppConfig.dailyEpoch` set to the launch day (Daily #1).
- [ ] Real AdMob app and unit IDs (Dart config + both native files), and a
      consent message set up in AdMob.
- [ ] IAP products created in both stores; shop tested on a test track.
- [ ] Firebase config files added (and the Gradle plugin on Android).
- [ ] Bundle ID changed from `com.example.shedlock`.
- [ ] Upload keystore + `android/key.properties`; version bumped.
- [ ] Privacy policy URL (required by AdMob, Play and the App Store) and the
      Play "Data safety" / App Store privacy forms. The app uses advertising
      ID, analytics and purchase history.
- [ ] Content rating questionnaire. Ads are shown, so declare "contains ads".
- [ ] `flutter analyze && flutter test` green.

## Licences

- Code: yours.
- Font: Press Start 2P, © The Press Start 2P Project Authors, SIL Open Font License 1.1
  ([assets/fonts/OFL.txt](assets/fonts/OFL.txt)).
- Sound effects and pixel art: original, generated by the scripts in `tool/`.
