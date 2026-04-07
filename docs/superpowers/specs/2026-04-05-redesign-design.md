# Awe — Redesign Spec
**Date:** 2026-04-05
**Status:** Approved

---

## Overview

Major simplification: the multi-step entry sequence (splash → montage → video → quote) collapses into splash + one consolidated video. The four hub options are renamed and unified behind a single reusable `GalleryScreen`. Dead code is removed throughout.

---

## Entry Flow

```
SplashScreen (existing "Awe" text, keep as-is)
  ↓ auto-advance
ExperienceScreen (plays assets/video/the_experience.mp4)
  ↓ on video complete → navigate directly to HubScreen (no pause/fade)
HubScreen
```

`has_seen_intro` flag behaviour unchanged: first launch plays the full sequence, return launches go straight to `HubScreen`.

---

## Screens

### Deleted
- `montage_screen.dart`
- `video_screen.dart`
- `quote_screen.dart`
- `micro_awe_screen.dart`
- `cosmic_awe_screen.dart`
- `power_of_nature_screen.dart`
- `audio_engine.dart` (video carries its own audio; `just_audio` dependency removed from pubspec)

### Kept
- `splash_screen.dart` — unchanged
- `hub_screen.dart` — redesigned (see below)
- `orientation_gate_screen.dart` — unchanged
- `sensor_service.dart` — kept, unused for now (Stars Simulation later)

### New / Replaced
- `experience_screen.dart` — full-screen `video_player` playing `the_experience.mp4`. On completion navigates directly to `HubScreen`.
- `gallery_screen.dart` — reusable full-screen swipeable gallery with pinch-to-zoom. Accepts `title` (String) and `imagePaths` (List<String>). Back button returns to hub.

---

## Hub Screen

Landscape row layout (unchanged structure). Four tiles + one action button below:

| Position | Label | Behaviour |
|---|---|---|
| Tile 1 | Intricate | Opens `GalleryScreen(title: 'Intricate', imagePaths: intricate/)` |
| Tile 2 | Majestic | Opens `GalleryScreen(title: 'Majestic', imagePaths: majestic/)` |
| Tile 3 | Cosmic | Opens `GalleryScreen(title: 'Cosmic', imagePaths: cosmic/)` |
| Tile 4 | Stars Simulation | Placeholder tile — shows coming-soon state, non-navigable |
| Below tiles | "Relive the Experience" | Navigates to `ExperienceScreen` (replays video regardless of flag) |

Sublabels per tile:
- Intricate → "The Small"
- Majestic → "The Grand"
- Cosmic → "The Infinite"
- Stars Simulation → "Coming Soon"

---

## AppPreferences

Remove all keys except `has_seen_intro`:
- ~~`montage_resume_index`~~
- ~~`montage_resume_elapsed_ms`~~
- ~~`audio_resume_position_ms`~~

Remaining API: `hasSeenIntro`, `setHasSeenIntro(bool)`.

---

## Assets

### Video
```
assets/video/the_experience.mp4    ← drop in manually
```

### Images
```
assets/images/intricate/           ← renamed from micro_awe/
  01.jpg, 02.jpg, ...

assets/images/majestic/            ← new folder
  01.jpg, 02.jpg, ...

assets/images/cosmic/              ← renamed from cosmic_awe/
  01.jpg, 02.jpg, ...
```

### Deleted
```
assets/images/montage_01.jpg … montage_22.jpg
assets/images/micro_awe/
assets/images/cosmic_awe/
assets/images/power_of_nature/
assets/audio/
```

### pubspec.yaml changes
- Remove `assets/images/micro_awe/`, `assets/images/cosmic_awe/`, `assets/images/power_of_nature/`, `assets/audio/`
- Add `assets/images/intricate/`, `assets/images/majestic/`, `assets/images/cosmic/`
- Remove `just_audio` dependency

---

## Dependencies Removed
- `just_audio` — no longer needed

## Dependencies Kept
- `video_player` — used by `ExperienceScreen`
- `sensors_plus` — kept for future Stars Simulation
- `shared_preferences` — `has_seen_intro` flag
- `provider` — kept if used elsewhere

---

## What Is Not Changing
- `OrientationGateScreen` (landscape gate)
- `SplashScreen` (the "Awe" title)
- `SensorService` abstraction
- Hub landscape row layout
- Navigation pattern (`Navigator.pushReplacement`)
