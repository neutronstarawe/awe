# Awe — Design Spec
**Date:** 2026-04-02
**Status:** Approved
**Platform:** Flutter (iOS 14+ / Android 8.0+)

---

## Overview

Awe is a sensory intervention app that disrupts state rumination by guiding the user through a cinematic micro-to-macro visual and auditory journey. It is linear by design and experiential in intent — not a utility.

Two phases:
- **Phase 1 (Passive):** Automated cinematic sequence — Splash → Image Montage → Milky Way Video → Closing Quote
- **Phase 2 (Interactive):** 2×2 Choice Hub with four exploration modules

Phase 1 plays on first launch only. Subsequent launches route directly to the Choice Hub. The Reset tile in the hub replays Phase 1 regardless of the flag.

---

## Architecture

### Approach
Linear, journey-first (Option A). Build and integration-test each stage in the exact order a user experiences it. No speculative abstraction.

### State Management
No heavy state library. Two mechanisms:
- `AudioEngine` — singleton `ChangeNotifier`, injected via `InheritedWidget`. Holds playback position, sync state, lifecycle hooks.
- `SharedPreferences` — persistence for `has_seen_intro` flag and montage resume snapshot.

Navigation is plain `Navigator.push/pop`. Local `StatefulWidget` state for everything else.

### Resume on Interruption
`WidgetsBindingObserver` at the root watches `AppLifecycleState`. On `paused`, the audio engine and `MontageController` snapshot their state to `SharedPreferences`. On `resumed`, the active screen restores from the snapshot.

---

## Project Structure

```
lib/
  main.dart               # launch check → route decision
  app.dart                # MaterialApp, named routes
  core/
    audio/                # AudioEngine (play, pause, resume, A/V sync)
    persistence/          # SharedPreferences wrapper
    assets/               # asset preloader (precacheImage)
  features/
    splash/
    montage/              # MontageController + crossfade UI
    video/
    quote/
    hub/
    micro_awe/
    cosmic_awe/
    power_of_nature/
assets/
  images/                 # 22 montage placeholders + gallery placeholders
  video/                  # ESO video placeholder
  audio/                  # music placeholder + ambient drone placeholder
integration_test/
  stage_01_scaffold_test.dart
  stage_02_splash_test.dart
  stage_03_audio_engine_test.dart
  stage_04_montage_test.dart
  stage_05_video_test.dart
  stage_06_av_sync_test.dart
  stage_07_quote_test.dart
  stage_08_hub_test.dart
  stage_09_micro_awe_test.dart
  stage_10_cosmic_awe_test.dart
  stage_11_power_of_nature_test.dart
  stage_12_end_to_end_test.dart
```

---

## Build Stages

| Stage | Deliverable | Integration Test |
|---|---|---|
| 1 | Flutter scaffold, pubspec, routes, first-launch check | App launches → routes correctly based on `has_seen_intro` flag |
| 2 | Splash screen (black, text, drone fade-in, 4s auto-advance) | Splash appears → auto-navigates after ~4s |
| 3 | AudioEngine (play, pause, resume position, lifecycle hooks) — built before screens that depend on it | Audio starts → app backgrounded → resumed → position correct |
| 4 | Image montage (22 placeholder crossfades, full-bleed, 58s) | Montage runs at correct cadence → navigates to video at end |
| 5 | Video player (placeholder MP4, 2× speed, dissolve-in) | Video starts at 2× → plays through → navigates to quote |
| 6 | A/V sync validation (music climax locks to video frame at 2:13) | Sync offset asserted via `VideoPlayerController.position`; climax timestamp verified |
| 7 | Closing quote (fade-in, sets `has_seen_intro`, transitions to hub) | Quote appears → flag written → hub loads |
| 8 | Choice Hub (2×2 grid, four tiles) | All four tiles route correctly; Reset re-enters montage |
| 9 | Micro Awe (swipeable gallery, pinch-to-zoom) | Swipe advances images; zoom gesture scales correctly |
| 10 | Cosmic Awe (gyroscope parallax, ≤30dp offset) | Simulated gyro input produces bounded parallax offset |
| 11 | Power of Nature (static image + caption, back nav) | Screen loads; back returns to hub |
| 12 | Full end-to-end flow + return-launch routing | Cold launch → Phase 1 → Hub; second launch → Hub directly |

---

## Critical Technical Details

### A/V Sync (Stage 6)
The music starts at `t=0`. The montage runs 58s. The video must be pre-trimmed so that when playback starts at `t=58s` (app clock), the Milky Way reveal frame lands exactly at `t=2:13` (133s app clock). This means the video asset itself must start ~7.5s before the reveal frame; at 2× speed, ~3.75s of video elapses before the reveal.

The precise offset is calculated when the real ESO video asset arrives. During development, the placeholder video has a visible frame marker at the expected sync point. Integration tests assert `VideoPlayerController.position` against the expected timestamp.

### Montage Resume
`MontageController` (a `ChangeNotifier`) tracks `currentImageIndex` and `elapsedWithinImage`. On `AppLifecycleState.paused`, it snapshots both values + audio position to `SharedPreferences`. On resume, it restores index, seeks audio, and continues the crossfade from the correct frame.

### Gyroscope Parallax (Cosmic Awe)
`sensors_plus` emits a `GyroscopeEvent` stream. The parallax widget accumulates `event.x` / `event.y`, clamps to ±30dp, and drives `Transform.translate`. A thin `SensorService` abstraction over `SensorsPlatform` allows integration tests to inject a fake stream without real hardware.

### Asset Preloading
All 22 montage images are preloaded via `precacheImage` before the splash screen auto-advances. Video and audio are bundled as local assets — no network calls.

---

## Asset Inventory (Placeholders During Development)

| Asset | Count | Placeholder |
|---|---|---|
| Montage images (JPEG) | 22 | Solid-colour placeholders, labelled by scale stage |
| Gallery images (JPEG) | 5–10 per Phase 2 module | Solid-colour placeholders |
| ESO Milky Way video (MP4) | 1 | Short placeholder with visible sync marker frame |
| Music — *La cathédrale engloutie* remix | 1 | Tone file with audible marker at 2:13 |
| Ambient drone (loopable) | 1 | Loopable tone |

Real assets dropped in at end; no code changes required.

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  video_player: ^2.x
  sensors_plus: ^4.x
  audioplayers: ^6.x
  flutter_animate: ^4.x
  shared_preferences: ^2.x

dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```
