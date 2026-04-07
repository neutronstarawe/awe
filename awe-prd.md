# Product Requirements Document
# Awe — Sensory Intervention App

**Version:** 0.1 (Draft)
**Author:** Rosh
**Date:** April 2026
**Platform:** Flutter (iOS & Android)
**Status:** Pre-Development

---

## 1. Overview

### 1.1 Product Summary

Awe is a mobile application designed as a sensory-based digital intervention to disrupt **state rumination** — the repetitive, unproductive looping of anxious or overwhelming thought patterns. It achieves this by guiding the user through a curated *Successive Scaling* visual and auditory journey: from the microscopic detail of a snowflake to the cosmic expanse of the Milky Way.

The app is **not** a utility, productivity tool, or social platform. It is closer to an experiential installation or guided meditation — linear by design, immersive by intent.

### 1.2 Core Design Philosophy

> *"Move the user from the smallest detail to the largest scale possible in under 4 minutes."*

The psychological mechanism is **awe induction**: exposure to stimuli that are vast, intricate, or powerful enough to temporarily dissolve self-referential thought. The app operationalizes this through cinematic sequencing, precise audio-visual synchronisation, and optional interactive exploration.

---

## 2. Feature Specification

### 2.1 Phase 1 — The Cinematic Induction (Passive)

This phase is entirely automated. No user interaction is required or expected.

#### 2.1.1 Splash Screen

- **Background:** Pure black (`#000000`)
- **Text:** *"Sit back, relax, allow yourself to breathe."*
- **Typography:** Light weight serif or thin sans-serif; white; centred
- **Duration:** 4–5 seconds before auto-transitioning
- **Audio:** Background ambient drone begins at very low volume, fading in

#### 2.1.2 The Ascent — Image Montage

A 58-second automated cross-fade sequence of **22 curated images**, moving from the micro to the macro along the following conceptual arc:

| Scale Stage | Representative Subject |
|---|---|
| Micro | Snowflake crystal (extreme macro) |
| Micro-Mid | Leaf cell structure / Butterfly wing |
| Ground | Forest canopy, woodland floor |
| Fauna | Animal migration (aerial view) |
| Landscape | Mountain range |
| Polar | Antarctic ice shelf |
| Planetary | Earth from low orbit / horizon |

**Timing Logic:**

- Total duration: ~58 seconds
- Images: 22
- Time per image: ~2.5 seconds visible
- Cross-fade duration: ~1 second (overlapping)
- Effective per-image time: 2.5s display + 1s dissolve = ~2.64s gross

**Technical requirements:**
- Images preloaded as assets (not network-fetched)
- Cross-fade implemented via `AnimationController` with `FadeTransition` stacking
- No user-visible UI chrome during this phase (full bleed, no status bar)

#### 2.1.3 The Galactic Reveal — Video Transition

At the 58-second mark, the final image (Earth horizon) dissolves into the **ESO Milky Way video**, played at **2x speed** using `video_player` plugin.

**Audio-Visual Synchronisation (Critical):**

| Time (app clock) | Event |
|---|---|
| `0:00` | *La cathedrale engloutie* (Remix) begins |
| `0:58` | Image montage ends; ESO video begins |
| `~2:13` | Musical climax must land precisely when Milky Way is fully revealed |

> **Note:** This sync is the centrepiece of the experience. The video start time offset and playback speed must be calculated and validated so the musical climax lands on the correct video frame. This likely requires trimming or offsetting the video asset.

#### 2.1.4 The Anchor — Closing Quote

Video fades to black. A quote appears, held for 6–8 seconds:

> *"The same hand that crafted the furthest galaxy designed the intricate patterns of your life."*

- **Typography:** Italicised serif, white on black, centred, fade-in animation
- **Transition:** Gentle fade to Phase 2 (Choice Hub)

---

### 2.2 Phase 2 — The Choice Hub (Interactive)

After Phase 1 completes, the user arrives at a **2x2 Grid Menu** offering four exploration modes.

#### Grid Layout

```
+------------------+------------------+
|  Micro Awe       |  Cosmic Awe      |
|  (The Intricate) |  (The Vast)      |
+------------------+------------------+
|  Power of Nature |  Reset           |
|  (Neg. Awe)      |                  |
+------------------+------------------+
```

#### 2.2.1 Micro Awe — *The Intricate*

- **Content:** Gallery of 5–10 high-resolution macro photographs
  - Ice crystals, butterfly wing scales, salt crystals, leaf cell structure
- **Interaction:** Swipeable or tappable gallery; pinch-to-zoom supported
- **Purpose:** Reinforce that complexity and beauty exist at the smallest scale

#### 2.2.2 Cosmic Awe — *The Vast*

- **Feature:** Star Parallax Screen
- **Tech:** `sensors_plus` — subscribes to device gyroscope stream
- **Behaviour:** As user tilts phone, high-resolution deep-space background image shifts on X/Y axes, creating a **3D window-into-space** parallax effect
- **Sensitivity:** Max parallax offset ~30dp; subtle, not disorienting
- **Content:** Single deep-space image (Hubble Deep Field or equivalent NASA/ESA open licence)

#### 2.2.3 Power of Nature — *The Negative Awe*

- **Content:** Single powerful image — eye of a hurricane, towering lightning strike, or volcanic eruption
- **Purpose:** Validates feelings of being overwhelmed. Places the user's sense of being "too much" into a context of awe rather than crisis — observational, not threatening
- **Interaction:** Static display with optional caption. Singular and intentional.

#### 2.2.4 Reset

- Restarts the **Phase 1 image montage** (not the full app cold-start)
- Music restarts from `0:00`
- No confirmation prompt required — single tap to re-enter

---

## 3. Technical Specification

### 4.1 Framework & Platform

| Item | Detail |
|---|---|
| Framework | Flutter (stable channel) |
| Target Platforms | iOS 14+ / Android 8.0+ |
| State Management | Minimal — linear navigation stack; no complex state |
| Navigation | Simple `push/pop` is sufficient |

### 4.2 Key Plugins

| Plugin | Purpose |
|---|---|
| `video_player` | ESO video playback with `playbackSpeed: 2.0` |
| `sensors_plus` | Gyroscope stream for Cosmic Awe parallax |
| `audioplayers` | Background music + ambient drone |
| `flutter_animate` or manual `AnimationController` | Cross-fade transitions for image montage |

### 4.3 Asset Inventory

| Asset Type | Count | Notes |
|---|---|---|
| High-res JPEG (montage) | 22 | Compressed to <= 300KB each; preloaded |
| High-res JPEG (galleries) | 5–12 | Phase 2 modules |
| MP4 Video | 1 | ESO Milky Way; may need pre-trimmed version |
| Audio — Music | 1 | *La cathedrale engloutie* Remix; MP3 or AAC |
| Audio — Ambient Drone | 1 | Background texture; loopable |

**Estimated bundle size:** ~35–50MB (images + video + audio)

### 4.4 Performance Requirements

- Cold launch to Splash Screen: <= 2 seconds
- Phase 1 cross-fades: no frame drops; target 60fps
- Gyroscope parallax: <= 16ms sensor-to-render latency
- Video must not buffer mid-play (local asset only)

---

## 4. Audio Design

| Moment | Audio Behaviour |
|---|---|
| Splash Screen | Ambient drone fades in (very low volume) |
| Montage begins | Drone sustains; music not yet started |
| Music start (`0:00`) | *La cathedrale engloutie* begins simultaneously with montage |
| Video transition | Seamless audio continuation — no gap |
| Musical climax (`2:13`) | Milky Way fully revealed in video |
| Closing quote | Music fades out slowly |
| Phase 2 hub | Optional: ambient drone returns at low level |
| Phase 2 modules | Silence or subtle ambient; no music (except Reset) |

---

## 5. First-Launch vs. Return-Launch Behaviour

Phase 1 plays **only on the first launch**. On all subsequent opens, the app routes directly to the Choice Hub.

**Implementation:**

- On Phase 1 completion (after the Anchor quote), write a flag to `SharedPreferences`: `has_seen_intro = true`
- On every app launch, check this flag before routing:
  - Flag absent → route to Splash Screen (Phase 1)
  - Flag present → route directly to Choice Hub (Phase 2)
- The **Reset** tile in the hub restarts the Phase 1 montage regardless of the flag (intentional replay)

---

## 6. References

- ESO Videos: https://www.eso.org/public/videos/
- Flutter `video_player`: https://pub.dev/packages/video_player
- Flutter `sensors_plus`: https://pub.dev/packages/sensors_plus
- Flutter `audioplayers`: https://pub.dev/packages/audioplayers

---

*Document Status: Draft v0.1 — For internal review only*
