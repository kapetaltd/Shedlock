# Shedlock: build plan

*Shed your tail. Lock your prey.*

Approved in Phase 1. This file records the agreed architecture and decisions so
later phases stay consistent.

## Phases
1. Plan (done)
2. Core logic + tests (pure Dart): classic snake, shed tail, runners, rewind, seeded RNG
3. Playable Flame game: Endless mode, retro LCD visuals
4. Daily Challenge, share result, streaks
5. Ads, IAP, analytics (Google test IDs)
6. Polish: sound, haptics, settings, app icon, edge cases, release build

## Architecture
- `lib/core/`: pure Dart, no Flutter/Flame/package imports (enforced by a test).
  `GameEngine.step(state, input) → (state, events)` is the only thing that
  changes game state.
- `lib/game/`: Flame components. Reads `GameState`, plays `GameEvent`s, owns
  the `FixedStepClock`.
- `lib/ui/`: screens. `lib/services/`: ads, IAP, analytics, storage, audio,
  haptics, share (interface + real + fake). `lib/config/`: IDs and app constants.

## Determinism rules
- All game time is *simulated* ms (sum of tick intervals): wall fade, shed
  cooldown and the rewind window never read the wall clock.
- Own PRNG (mulberry32, 32-bit safe on the web). Verified against the JS
  reference and run under both the Dart VM and dart2js.
- Separate RNG streams per purpose (`layout`, `food`, `runner-spawn`,
  `runner-move`), derived from the run seed with FNV-1a.
- Daily seed = FNV-1a of `shedlock-YYYY-MM-DD` (UTC date).
- Food: each spawn draws exactly (x, y). A blocked candidate scans forward in
  row-major order. The n-th candidate is identical for every player that day.
- Runner spawn: one (roll, x, y) draw per normal food eaten.

## Decisions (approved defaults)
| Topic | Decision |
|---|---|
| Ranked daily | 1 free rewind only; no ad rewinds or continues (`RunRules.rankedDaily`) |
| Endless / daily practice | 1 free rewind + up to 2 rewarded-ad rewinds + 1 rewarded continue |
| Continue | Score kept; snake cut to 3 segments and placed at the nearest free spot facing 4 clear cells; resumes after a countdown |
| Lock bonus | Flat 100 (configurable), independent of the multiplier |
| Multiplier | +10% per segment above start length; points = 10 × multiplier, integer maths |
| Daily #1 | 2026-10-01 UTC placeholder in `AppConfig.dailyEpoch` (set to launch day) |
| Firebase | Analytics no-ops until config files are added |
| Git | One branch + draft PR per phase |

## Notes vs the original plan
- `lock_detector.dart` and `scoring.dart` were folded into `RunnerAi.isLocked`
  and `GameConfig.foodPoints/multiplierPercent`: each was only a few lines.
- Only one runner can be on the board at a time.
- Ad policy, streak and share-text logic arrive with their phases (4 and 5).

## Phase 3 notes
- Touch input is a Flutter `GestureDetector` over the whole game screen
  (`lib/game/game_input.dart`), so swipes outside the board still count.
  Keyboard input (arrows/WASD, Space, P) is handled by the Flame game.
- `PlaceholderAdsService` grants rewarded-ad rewards instantly until AdMob
  arrives in Phase 5, so the rewind/continue flow is playable now.
- Pixel font: Press Start 2P (SIL OFL 1.1, bundled in `assets/fonts`).

## Phase 4 notes (Daily Challenge)
- The ranked attempt is marked as used the moment the run starts, so
  closing the app mid-run cannot buy a retry. Such a day shows as
  "not finished" and gives no streak.
- A ranked run ends when the player taps END RUN (after death or from
  pause), or automatically at death once the free rewind is spent.
  System back pauses instead of leaving.
- Practice opens only after the ranked attempt, so nobody can learn the
  board first.
- A run that crosses midnight UTC counts for the day it started.
- Streak = consecutive UTC days with a finished ranked run. It shows as 0
  once a day is missed.
- Share text: `Shedlock #N 🐍 score pts`, then food/locks/sheds (and rewinds
  if used), then a 5-square grid of how each fifth of the run went
  (⬛🟩🟨🟧, 🔒 if a lock happened), then the tagline.
- Logic is in `lib/core/daily/`; storage and glue are in
  `lib/services/daily_service.dart`.

## Phase 5 notes (monetisation and analytics)
- `AdsService` (AdMob: preloading, retry with backoff, UMP consent) is the raw
  SDK layer. `AdCoordinator` applies the rules (`InterstitialPolicy`) and
  logs analytics. Interstitials are only requested at run-to-menu moments
  (PLAY AGAIN / HOME after a finished run), never during play.
- A "completed run" = the player leaves game over, quits from pause, or a
  ranked daily is finished. Each one logs `run_end` and counts towards
  pacing.
- Sessions: a cold start, or coming back after 30+ minutes in the
  background. Logged as `game_session_start`, because Firebase reserves
  `session_start` for its own automatic event.
- IAP: four non-consumables. Ownership is cached locally and restorable.
  There is no server-side receipt validation, which is acceptable for
  cosmetics and Remove Ads.
- Cosmetics: snake skins, trails and board themes (live palette switch).
  The free defaults are always available. Items from a pack the player no
  longer owns fall back to the free ones.
- Web and tests use `PlaceholderAdsService` + `FakeIapService`. On a device,
  `--dart-define=FAKE_STORE=true` enables the fake store.

## Phase 6 notes (polish)
- Sound: six original effects (eat, shed, lock, death, rewind, countdown
  tick), synthesised by `tool/gen_sfx.dart` and played through low-latency
  `flame_audio` pools.
- Haptics: light on eat, medium on shed and rewind, heavy on lock and death,
  a selection click when a shed is refused.
- Settings: sound, haptics and screen shake (motion sensitivity),
  persisted; privacy options (UMP) shown only where required; restore
  purchases; how to play; credits.
- Icon: generated from the logo pixel art (`tool/gen_icon.py`) → launcher
  icons (adaptive on Android) and a native splash in the LCD colour, so
  there is no white flash. Display name "Shedlock" on both platforms.
- Edge cases handled:
  - pause on any lifecycle change;
  - home refreshes on resume, so the daily puzzle rolls over at UTC midnight;
  - double taps between runs are guarded;
  - system text scale is capped at 1.3x for the pixel font;
  - corrupt stored data falls back to defaults;
  - a backwards clock never breaks the streak.
- Release signing reads `android/key.properties` and falls back to the debug
  key without it.

## Environment notes
- The cloud container has no `/dev/kvm`, so no Android emulator. UI
  verification uses the Flutter web build in headless Chromium.
- `dl.google.com` is blocked by the environment network policy, so there is no
  Android SDK and no APK/AAB builds from the container until it is allowed.
