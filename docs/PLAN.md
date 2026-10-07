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
| Daily #1 | 2026-11-01 UTC placeholder in `AppConfig.dailyEpoch` |
| Firebase | Analytics no-ops until config files are added |
| Git | One branch + draft PR per phase |

## Notes vs the original plan
- `lock_detector.dart` and `scoring.dart` were folded into `RunnerAi.isLocked`
  and `GameConfig.foodPoints/multiplierPercent`: each was only a few lines.
- Only one runner can be on the board at a time.
- Ad policy, streak and share-text logic arrive with their phases (4 and 5).

## Environment notes
- The cloud container has no `/dev/kvm`, so no Android emulator. UI
  verification uses the Flutter web build in headless Chromium.
- `dl.google.com` is blocked by the environment network policy, so there is no
  Android SDK and no APK/AAB builds from the container until it is allowed.
