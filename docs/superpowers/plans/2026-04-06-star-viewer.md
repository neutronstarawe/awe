# Star Viewer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a real-time sky viewer that uses the phone's GPS + compass + accelerometer to show the actual stars and constellation lines visible in whatever direction the phone is pointing.

**Architecture:** A `StarCatalog` loads ~1 500 stars (mag ≤ 5.5) and constellation line data from bundled JSON assets. A `SkyOrientationService` fuses `flutter_compass` (azimuth) with `sensors_plus` accelerometer (altitude) into a single stream. On each orientation update, `astronomy.dart` converts every star's RA/Dec → Alt/Az for the observer's GPS location + current UTC, `SkyProjection` maps visible stars to screen pixels via gnomonic projection, and `SkyPainter` draws them on a black canvas with constellation lines.

**Tech Stack:** Flutter 3.x, `geolocator ^12`, `flutter_compass ^0.8`, `sensors_plus ^4` (already present), `CustomPainter`, bundled JSON star/constellation assets, pure Dart astronomy math.

**Important:** This feature requires a real iOS/Android device. The macOS desktop build will not have compass or meaningful accelerometer data. Test on device.

**CRITICAL RULE: Do NOT modify `lib/core/app_preferences.dart` for any reason.**

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `pubspec.yaml` | Modify | Add geolocator, flutter_compass; register assets/data/ |
| `ios/Runner/Info.plist` | Modify | Location permission strings |
| `android/app/src/main/AndroidManifest.xml` | Modify | Location permissions |
| `assets/data/stars.json` | Create | ~1 500 stars: id (HIP), ra (rad), dec (rad), mag, name? |
| `assets/data/constellations.json` | Create | 88 constellations: name → [[hipFrom,hipTo], …] |
| `lib/stars/star.dart` | Create | `Star` model + `fromJson` |
| `lib/stars/constellation.dart` | Create | `Constellation` model + `fromJson` |
| `lib/stars/star_catalog.dart` | Create | Load + filter by magnitude; lookup by HIP id |
| `lib/stars/astronomy.dart` | Create | Pure functions: Julian date, LST, RA/Dec→Alt/Az |
| `lib/stars/sky_projection.dart` | Create | Gnomonic projection: Alt/Az → screen Offset |
| `lib/stars/sky_orientation.dart` | Create | `SkyOrientation` value + abstract source + real impl |
| `lib/stars/sky_painter.dart` | Create | `CustomPainter` — draws stars + constellation lines |
| `lib/screens/stars_screen.dart` | Create | Wires catalog + orientation + painter; handles permissions |
| `lib/screens/hub_screen.dart` | Modify | Enable Stars Simulation tile → navigate to StarsScreen |
| `test/stars/star_catalog_test.dart` | Create | Load/filter tests |
| `test/stars/astronomy_test.dart` | Create | Known-position tests |
| `test/stars/sky_projection_test.dart` | Create | Projection geometry tests |
| `test/stars/sky_orientation_test.dart` | Create | Fake stream tests |

---

## Task 1: Dependencies, permissions, and data assets

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `assets/data/stars.json`
- Create: `assets/data/constellations.json`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Under `dependencies:`, add:
```yaml
  geolocator: ^12.0.0
  flutter_compass: ^0.8.0
```

Under `flutter: assets:`, add:
```yaml
    - assets/data/
```

- [ ] **Step 2: Run pub get**

```bash
flutter pub get
```

Expected: `Got dependencies!` with no errors.

- [ ] **Step 3: Add iOS location permission strings to Info.plist**

In `ios/Runner/Info.plist`, inside the root `<dict>`, add:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>awe uses your location to show the correct stars for your position on Earth.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>awe uses your location to show the correct stars for your position on Earth.</string>
```

- [ ] **Step 4: Add Android location permission to AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, above the `<application>` tag, add:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

- [ ] **Step 5: Create the assets/data/ directory and generate stars.json**

Create `assets/data/` directory. Then run the Python script below to download the HYG star database and emit `assets/data/stars.json` (stars with magnitude ≤ 5.5, fields: id, ra in radians, dec in radians, mag, optional name):

```python
#!/usr/bin/env python3
# generate_stars.py — run from repo root
import csv, json, math, urllib.request, os

URL = "https://raw.githubusercontent.com/astronexus/HYG-Database/main/hyg/v3/hyg.csv"
OUT = "assets/data/stars.json"
MAG_LIMIT = 5.5

os.makedirs("assets/data", exist_ok=True)

print("Downloading HYG catalog...")
with urllib.request.urlopen(URL) as r:
    lines = r.read().decode("utf-8").splitlines()

reader = csv.DictReader(lines)
stars = []
for row in reader:
    try:
        mag = float(row["mag"])
    except ValueError:
        continue
    if mag > MAG_LIMIT:
        continue
    hip = int(row["hip"]) if row["hip"] else 0
    if hip == 0:
        continue
    ra_rad = float(row["rarad"])
    dec_rad = float(row["decrad"])
    entry = {"id": hip, "ra": round(ra_rad, 6), "dec": round(dec_rad, 6), "mag": round(mag, 2)}
    name = row.get("proper", "").strip()
    if name:
        entry["name"] = name
    stars.append(entry)

stars.sort(key=lambda s: s["mag"])
with open(OUT, "w") as f:
    json.dump(stars, f, separators=(",", ":"))
print(f"Written {len(stars)} stars to {OUT}")
```

Run it:
```bash
python3 generate_stars.py
```

Expected: `Written ~1450 stars to assets/data/stars.json`

- [ ] **Step 6: Create constellations.json**

Run this script to fetch the IAU constellation line data:

```python
#!/usr/bin/env python3
# generate_constellations.py — run from repo root
import json, urllib.request

# Source: Stellarium constellation lines (HIP ids)
URL = "https://raw.githubusercontent.com/Stellarium/stellarium/master/skycultures/modern/constellation_lines.fab"
HYG_URL = "https://raw.githubusercontent.com/astronexus/HYG-Database/main/hyg/v3/hyg.csv"
OUT = "assets/data/constellations.json"

# Build HR→HIP map from HYG
import csv
print("Building HR→HIP map...")
with urllib.request.urlopen(HYG_URL) as r:
    lines = r.read().decode("utf-8").splitlines()
hr_to_hip = {}
for row in csv.DictReader(lines):
    if row["hr"] and row["hip"]:
        try:
            hr_to_hip[int(row["hr"])] = int(row["hip"])
        except ValueError:
            pass

print("Downloading constellation lines...")
with urllib.request.urlopen(URL) as r:
    fab = r.read().decode("utf-8")

constellations = {}
for line in fab.splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    parts = line.split()
    if len(parts) < 4:
        continue
    name = parts[0]
    n_lines = int(parts[1])
    ids = list(map(int, parts[2:]))
    lines_out = []
    for i in range(0, len(ids), 2):
        if i + 1 < len(ids):
            h1 = hr_to_hip.get(ids[i])
            h2 = hr_to_hip.get(ids[i+1])
            if h1 and h2:
                lines_out.append([h1, h2])
    if lines_out:
        constellations[name] = lines_out

with open(OUT, "w") as f:
    json.dump(constellations, f, separators=(",", ":"))
print(f"Written {len(constellations)} constellations to {OUT}")
```

Run it:
```bash
python3 generate_constellations.py
```

Expected: `Written ~88 constellations to assets/data/constellations.json`

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml assets/data/
git commit -m "feat: add geolocator/flutter_compass deps, location permissions, star+constellation data"
```

---

## Task 2: Star and Constellation models

**Files:**
- Create: `lib/stars/star.dart`
- Create: `lib/stars/constellation.dart`
- Create: `lib/stars/star_catalog.dart`
- Create: `test/stars/star_catalog_test.dart`

- [ ] **Step 1: Create lib/stars/star.dart**

```dart
class Star {
  final int id;       // HIP catalog number
  final double ra;    // Right ascension, radians
  final double dec;   // Declination, radians
  final double mag;   // Visual magnitude (lower = brighter)
  final String? name; // Common name, e.g. "Sirius"

  const Star({
    required this.id,
    required this.ra,
    required this.dec,
    required this.mag,
    this.name,
  });

  factory Star.fromJson(Map<String, dynamic> json) => Star(
        id: json['id'] as int,
        ra: (json['ra'] as num).toDouble(),
        dec: (json['dec'] as num).toDouble(),
        mag: (json['mag'] as num).toDouble(),
        name: json['name'] as String?,
      );
}
```

- [ ] **Step 2: Create lib/stars/constellation.dart**

```dart
class Constellation {
  final String name;
  final List<List<int>> lines; // each sub-list is [fromHIP, toHIP]

  const Constellation({required this.name, required this.lines});

  factory Constellation.fromJson(String name, List<dynamic> lines) =>
      Constellation(
        name: name,
        lines: lines
            .map((l) => (l as List).map((e) => e as int).toList())
            .toList(),
      );
}
```

- [ ] **Step 3: Create lib/stars/star_catalog.dart**

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'star.dart';
import 'constellation.dart';

class StarCatalog {
  final List<Star> stars;
  final List<Constellation> constellations;
  final Map<int, Star> _byId;

  StarCatalog({required this.stars, required this.constellations})
      : _byId = {for (final s in stars) s.id: s};

  Star? starById(int id) => _byId[id];

  List<Star> starsVisibleToNakedEye() =>
      stars.where((s) => s.mag <= 6.5).toList();

  static Future<StarCatalog> load(AssetBundle bundle) async {
    final starsRaw =
        jsonDecode(await bundle.loadString('assets/data/stars.json')) as List;
    final consRaw =
        jsonDecode(await bundle.loadString('assets/data/constellations.json'))
            as Map<String, dynamic>;

    return StarCatalog(
      stars: starsRaw
          .map((j) => Star.fromJson(j as Map<String, dynamic>))
          .toList(),
      constellations: consRaw.entries
          .map((e) => Constellation.fromJson(e.key, e.value as List))
          .toList(),
    );
  }
}
```

- [ ] **Step 4: Write the failing tests**

Create `test/stars/star_catalog_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/star.dart';
import 'package:awe/stars/constellation.dart';
import 'package:awe/stars/star_catalog.dart';

class _FakeBundle extends Fake implements AssetBundle {
  final String starsJson;
  final String consJson;

  _FakeBundle({required this.starsJson, required this.consJson});

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.contains('stars')) return starsJson;
    if (key.contains('constellations')) return consJson;
    throw UnsupportedError(key);
  }
}

void main() {
  final sampleStars = jsonEncode([
    {'id': 32349, 'ra': 1.7679, 'dec': -0.2911, 'mag': -1.46, 'name': 'Sirius'},
    {'id': 11767, 'ra': 0.6637, 'dec': 1.5580, 'mag': 1.97, 'name': 'Polaris'},
    {'id': 99999, 'ra': 0.0, 'dec': 0.0, 'mag': 7.5},
  ]);

  final sampleCons = jsonEncode({
    'Orion': [[24436, 25930], [25930, 26727]],
  });

  late StarCatalog catalog;

  setUp(() async {
    catalog = await StarCatalog.load(
        _FakeBundle(starsJson: sampleStars, consJson: sampleCons));
  });

  test('loads all stars', () {
    expect(catalog.stars.length, 3);
  });

  test('parses star fields correctly', () {
    final sirius = catalog.starById(32349)!;
    expect(sirius.name, 'Sirius');
    expect(sirius.mag, closeTo(-1.46, 0.001));
    expect(sirius.ra, closeTo(1.7679, 0.0001));
    expect(sirius.dec, closeTo(-0.2911, 0.0001));
  });

  test('starById returns null for unknown id', () {
    expect(catalog.starById(0), isNull);
  });

  test('starsVisibleToNakedEye filters out dim stars', () {
    final visible = catalog.starsVisibleToNakedEye();
    expect(visible.length, 2); // Sirius and Polaris, not the 7.5-mag one
  });

  test('loads constellations', () {
    expect(catalog.constellations.length, 1);
    expect(catalog.constellations.first.name, 'Orion');
    expect(catalog.constellations.first.lines.first, [24436, 25930]);
  });
}
```

- [ ] **Step 5: Run tests to verify they fail**

```bash
flutter test test/stars/star_catalog_test.dart
```

Expected: compilation error — `package:awe/stars/star.dart` not found yet. That is expected at this point.

- [ ] **Step 6: Run tests to verify they pass**

```bash
flutter test test/stars/star_catalog_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 7: Commit**

```bash
git add lib/stars/ test/stars/star_catalog_test.dart
git commit -m "feat: Star/Constellation models and StarCatalog loader with tests"
```

---

## Task 3: Astronomy math

**Files:**
- Create: `lib/stars/astronomy.dart`
- Create: `test/stars/astronomy_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/stars/astronomy_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/astronomy.dart';

void main() {
  group('julianDate', () {
    test('J2000.0 epoch is JD 2451545.0', () {
      // 2000 Jan 1, 12:00:00 UTC = J2000.0
      final jd = julianDate(DateTime.utc(2000, 1, 1, 12, 0, 0));
      expect(jd, closeTo(2451545.0, 0.001));
    });

    test('1999 Jan 1.0 UTC is JD 2451179.5', () {
      final jd = julianDate(DateTime.utc(1999, 1, 1, 0, 0, 0));
      expect(jd, closeTo(2451179.5, 0.001));
    });
  });

  group('raDecToAltAz', () {
    // Polaris: HIP 11767, RA=2.5303h → 0.6637 rad, Dec=89.2641° → 1.5580 rad
    // Key property: altitude of Polaris ≈ observer latitude (within ~1°)
    const polarisRa = 0.6637;  // radians
    const polarisDec = 1.5580; // radians

    test('Polaris altitude ≈ latitude at 52°N', () {
      const latRad = 52.0 * pi / 180;
      // Use any LST — Polaris is close enough to pole that hour angle barely matters
      // At transit (ha=0): LST = RA
      final lst = polarisRa;
      final (alt, _) = raDecToAltAz(
        ra: polarisRa, dec: polarisDec, latRad: latRad, lst: lst,
      );
      expect(alt * 180 / pi, closeTo(52.0, 1.0)); // within 1°
    });

    test('Polaris altitude ≈ 0° at equator', () {
      const latRad = 0.0;
      final lst = polarisRa;
      final (alt, _) = raDecToAltAz(
        ra: polarisRa, dec: polarisDec, latRad: latRad, lst: lst,
      );
      expect(alt * 180 / pi, closeTo(0.0, 1.0));
    });

    test('Star on equator transiting meridian is at altitude = 90° - lat', () {
      // dec=0, ha=0 → alt = 90° - lat
      const latDeg = 40.0;
      const latRad = latDeg * pi / 180;
      const ra = 1.0;
      final lst = ra; // ha = 0 at transit
      final (alt, _) = raDecToAltAz(
        ra: ra, dec: 0.0, latRad: latRad, lst: lst,
      );
      expect(alt * 180 / pi, closeTo(90.0 - latDeg, 0.1));
    });

    test('Star on meridian has azimuth ≈ 0° (North) or 180° (South)', () {
      // Polaris transiting at 52°N should be roughly North (az ≈ 0 or 2π)
      const latRad = 52.0 * pi / 180;
      final lst = polarisRa;
      final (_, az) = raDecToAltAz(
        ra: polarisRa, dec: polarisDec, latRad: latRad, lst: lst,
      );
      final azDeg = az * 180 / pi;
      // az should be near 0° or near 360°
      expect(azDeg < 5.0 || azDeg > 355.0, isTrue);
    });

    test('altitude clamps to valid range', () {
      // Sanity: no NaN, no values outside [-90°, 90°]
      final (alt, az) = raDecToAltAz(
        ra: 0.0, dec: 0.0, latRad: 0.0, lst: pi,
      );
      expect(alt, isNot(isNaN));
      expect(az, isNot(isNaN));
      expect(alt * 180 / pi, inInclusiveRange(-90.0, 90.0));
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/stars/astronomy_test.dart
```

Expected: compilation error — `astronomy.dart` not found.

- [ ] **Step 3: Create lib/stars/astronomy.dart**

```dart
import 'dart:math';

/// Julian Date for the given UTC instant.
double julianDate(DateTime utc) {
  final y = utc.year;
  final m = utc.month;
  final d = utc.day +
      (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d +
      (153 * mm + 2) ~/ 5 +
      365 * yy +
      yy ~/ 4 -
      yy ~/ 100 +
      yy ~/ 400 -
      32045;
}

/// Local Sidereal Time in radians.
/// [longitudeRad]: observer longitude, positive East.
double localSiderealTime(double longitudeRad, DateTime utc) {
  final jd = julianDate(utc);
  final t = (jd - 2451545.0) / 36525.0;
  // GMST in radians (IAU formula)
  final gmst = 4.894961213 +
      6.300388099 * (jd - 2451545.0) +
      t * t * (6.77e-6 - t * 4.5e-10);
  return (gmst + longitudeRad) % (2 * pi);
}

/// Converts equatorial (RA/Dec) to horizontal (Alt/Az) coordinates.
///
/// All angles in radians.
/// [ra]: right ascension.
/// [dec]: declination.
/// [latRad]: observer geodetic latitude, positive North.
/// [lst]: local sidereal time.
///
/// Returns (altitude, azimuth).
/// altitude: 0 = horizon, π/2 = zenith.
/// azimuth: 0 = North, π/2 = East (measured clockwise).
(double alt, double az) raDecToAltAz({
  required double ra,
  required double dec,
  required double latRad,
  required double lst,
}) {
  final ha = lst - ra; // hour angle

  final sinAlt =
      sin(dec) * sin(latRad) + cos(dec) * cos(latRad) * cos(ha);
  final alt = asin(sinAlt.clamp(-1.0, 1.0));

  final cosAlt = cos(alt);
  if (cosAlt.abs() < 1e-10) {
    // At zenith or nadir — azimuth is undefined, return 0
    return (alt, 0.0);
  }

  final cosAz =
      (sin(dec) - sin(alt) * sin(latRad)) / (cosAlt * cos(latRad));
  var az = acos(cosAz.clamp(-1.0, 1.0));
  // Quadrant correction: if hour angle is positive (star west of meridian),
  // azimuth is in western half (180°–360°).
  if (sin(ha) > 0) az = 2 * pi - az;

  return (alt, az);
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/stars/astronomy_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/stars/astronomy.dart test/stars/astronomy_test.dart
git commit -m "feat: astronomy math — Julian date, LST, RA/Dec→Alt/Az with tests"
```

---

## Task 4: Sky projection

**Files:**
- Create: `lib/stars/sky_projection.dart`
- Create: `test/stars/sky_projection_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/stars/sky_projection_test.dart`:

```dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/sky_projection.dart';

void main() {
  const size = Size(800, 600);
  const fov = 40.0 * pi / 180; // 40° half-angle FOV

  group('SkyProjection', () {
    test('center point projects to screen center', () {
      const centerAz = 1.0;
      const centerAlt = 0.5;
      final proj = SkyProjection(
        centerAz: centerAz, centerAlt: centerAlt,
        fovRadians: fov, screenSize: size,
      );
      final pos = proj.project(centerAlt, centerAz);
      expect(pos, isNotNull);
      expect(pos!.dx, closeTo(size.width / 2, 0.5));
      expect(pos.dy, closeTo(size.height / 2, 0.5));
    });

    test('star directly behind (opposite hemisphere) returns null', () {
      final proj = SkyProjection(
        centerAz: 0.0, centerAlt: 0.0,
        fovRadians: fov, screenSize: size,
      );
      // Directly behind: alt=0, az=pi (180° away)
      expect(proj.project(0.0, pi), isNull);
    });

    test('star far off-screen returns null', () {
      final proj = SkyProjection(
        centerAz: 0.0, centerAlt: 0.0,
        fovRadians: fov, screenSize: size,
      );
      // 90° away in azimuth — well outside 40° FOV
      expect(proj.project(0.0, pi / 2), isNull);
    });

    test('star slightly left of center projects left of screen center', () {
      const centerAz = 1.0;
      const centerAlt = 0.0;
      final proj = SkyProjection(
        centerAz: centerAz, centerAlt: centerAlt,
        fovRadians: fov, screenSize: size,
      );
      // 5° to the left (smaller az)
      final pos = proj.project(centerAlt, centerAz - 5 * pi / 180);
      expect(pos, isNotNull);
      expect(pos!.dx, lessThan(size.width / 2));
    });

    test('star slightly above center projects above screen center', () {
      const centerAz = 1.0;
      const centerAlt = 0.2;
      final proj = SkyProjection(
        centerAz: centerAz, centerAlt: centerAlt,
        fovRadians: fov, screenSize: size,
      );
      // 5° higher altitude
      final pos = proj.project(centerAlt + 5 * pi / 180, centerAz);
      expect(pos, isNotNull);
      expect(pos!.dy, lessThan(size.height / 2)); // higher alt = smaller dy
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/stars/sky_projection_test.dart
```

Expected: compilation error.

- [ ] **Step 3: Create lib/stars/sky_projection.dart**

```dart
import 'dart:math';
import 'dart:ui';

/// Gnomonic (tangent-plane) projection of the sky onto the screen.
///
/// The center of the screen corresponds to (centerAlt, centerAz).
/// Stars within [fovRadians] half-angle of center are projected to screen pixels.
class SkyProjection {
  final double centerAz;    // radians, 0=North clockwise
  final double centerAlt;   // radians, 0=horizon, π/2=zenith
  final double fovRadians;  // half-angle field of view in radians
  final Size screenSize;

  const SkyProjection({
    required this.centerAz,
    required this.centerAlt,
    required this.fovRadians,
    required this.screenSize,
  });

  /// Projects (alt, az) → screen [Offset]. Returns null if not on screen.
  Offset? project(double alt, double az) {
    // Angular distance from center (dot product of unit vectors)
    final cosD = sin(centerAlt) * sin(alt) +
        cos(centerAlt) * cos(alt) * cos(az - centerAz);

    // cosD <= 0 means behind us (> 90° away)
    if (cosD <= 0) return null;

    // Gnomonic projection: tangent-plane coords
    final dAz = az - centerAz;
    final x = cos(alt) * sin(dAz) / cosD;
    final y = (cos(centerAlt) * sin(alt) -
            sin(centerAlt) * cos(alt) * cos(dAz)) /
        cosD;

    // Scale: pixels per radian at center
    final scale = (screenSize.width / 2) / tan(fovRadians);

    final sx = screenSize.width / 2 + x * scale;
    final sy = screenSize.height / 2 - y * scale; // y flipped: up = smaller dy

    // Off-screen guard (50px margin)
    const margin = 50.0;
    if (sx < -margin || sx > screenSize.width + margin) return null;
    if (sy < -margin || sy > screenSize.height + margin) return null;

    return Offset(sx, sy);
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/stars/sky_projection_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/stars/sky_projection.dart test/stars/sky_projection_test.dart
git commit -m "feat: gnomonic sky projection with tests"
```

---

## Task 5: Phone sky orientation (sensor fusion)

**Files:**
- Create: `lib/stars/sky_orientation.dart`
- Create: `test/stars/sky_orientation_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/stars/sky_orientation_test.dart`:

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/sky_orientation.dart';

void main() {
  group('SkyOrientation value', () {
    test('stores azimuth and altitude', () {
      const o = SkyOrientation(azimuth: 1.2, altitude: 0.5);
      expect(o.azimuth, 1.2);
      expect(o.altitude, 0.5);
    });
  });

  group('FakeSkyOrientationSource', () {
    test('emits values pushed via emit()', () async {
      final source = FakeSkyOrientationSource();
      const expected = SkyOrientation(azimuth: 0.3, altitude: 0.8);

      final emitted = <SkyOrientation>[];
      final sub = source.stream.listen(emitted.add);
      source.emit(expected);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      source.dispose();

      expect(emitted.length, 1);
      expect(emitted.first.azimuth, expected.azimuth);
      expect(emitted.first.altitude, expected.altitude);
    });

    test('altitude from phone face-up accel (z≈+9.8) is ~90°', () {
      // When accelerometer z ≈ +9.8 (face-up), altitude should be ≈ π/2
      final alt = SkyOrientation.altitudeFromAccel(ax: 0, ay: 0, az: 9.8);
      expect(alt, closeTo(pi / 2, 0.05));
    });

    test('altitude from phone upright (z≈0) is ~0°', () {
      final alt = SkyOrientation.altitudeFromAccel(ax: 0, ay: -9.8, az: 0);
      expect(alt, closeTo(0.0, 0.05));
    });

    test('altitude from phone face-down (z≈-9.8) is ~-90°', () {
      final alt = SkyOrientation.altitudeFromAccel(ax: 0, ay: 0, az: -9.8);
      expect(alt, closeTo(-pi / 2, 0.05));
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/stars/sky_orientation_test.dart
```

Expected: compilation error.

- [ ] **Step 3: Create lib/stars/sky_orientation.dart**

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Represents where the phone camera is pointing in the sky.
class SkyOrientation {
  /// Compass bearing in radians (0=North, π/2=East, π=South, 3π/2=West).
  final double azimuth;

  /// Altitude above horizon in radians (0=horizon, π/2=zenith).
  final double altitude;

  const SkyOrientation({required this.azimuth, required this.altitude});

  /// Computes altitude from raw accelerometer values (m/s²).
  /// Face-up (z≈+9.81) → altitude ≈ π/2 (zenith).
  /// Upright (z≈0, y≈-9.81) → altitude ≈ 0 (horizon).
  static double altitudeFromAccel({
    required double ax,
    required double ay,
    required double az,
  }) {
    const g = 9.81;
    return asin((az / g).clamp(-1.0, 1.0));
  }
}

/// Abstract source — allows injection of a fake in tests.
abstract class SkyOrientationSource {
  Stream<SkyOrientation> get stream;
  void dispose();
}

/// Fake implementation for widget tests.
class FakeSkyOrientationSource implements SkyOrientationSource {
  final _controller = StreamController<SkyOrientation>.broadcast();

  void emit(SkyOrientation o) => _controller.add(o);

  @override
  Stream<SkyOrientation> get stream => _controller.stream;

  @override
  void dispose() => _controller.close();
}

/// Production implementation combining flutter_compass + accelerometer.
class RealSkyOrientationSource implements SkyOrientationSource {
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  final _controller = StreamController<SkyOrientation>.broadcast();

  double? _azimuth;
  double? _altitude;

  RealSkyOrientationSource() {
    _compassSub = FlutterCompass.events?.listen((e) {
      _azimuth = (e.heading ?? 0) * pi / 180;
      _tryEmit();
    });
    _accelSub = accelerometerEventStream().listen((e) {
      _altitude = SkyOrientation.altitudeFromAccel(ax: e.x, ay: e.y, az: e.z);
      _tryEmit();
    });
  }

  void _tryEmit() {
    final az = _azimuth;
    final alt = _altitude;
    if (az != null && alt != null) {
      _controller.add(SkyOrientation(azimuth: az, altitude: alt));
    }
  }

  @override
  Stream<SkyOrientation> get stream => _controller.stream;

  @override
  void dispose() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _controller.close();
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/stars/sky_orientation_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/stars/sky_orientation.dart test/stars/sky_orientation_test.dart
git commit -m "feat: SkyOrientation value + sensor fusion source (real + fake) with tests"
```

---

## Task 6: Sky painter

**Files:**
- Create: `lib/stars/sky_painter.dart`

Note: `CustomPainter` cannot be meaningfully unit-tested with `flutter_test` without a rendering context. The painter is tested end-to-end in Task 7's widget test via golden or smoke tests.

- [ ] **Step 1: Create lib/stars/sky_painter.dart**

```dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Color, Colors;
import '../stars/star.dart';
import '../stars/constellation.dart';
import '../stars/sky_projection.dart';
import '../stars/astronomy.dart';

class SkyPainter extends CustomPainter {
  final List<Star> stars;
  final List<Constellation> constellations;
  final Map<int, Star> starById;
  final double observerLat;   // radians
  final double lst;           // Local Sidereal Time, radians
  final SkyProjection projection;

  const SkyPainter({
    required this.stars,
    required this.constellations,
    required this.starById,
    required this.observerLat,
    required this.lst,
    required this.projection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000000),
    );

    // Pre-compute alt/az for all visible stars
    final projected = <Star, Offset>{};
    for (final star in stars) {
      final (alt, az) = raDecToAltAz(
        ra: star.ra, dec: star.dec, latRad: observerLat, lst: lst,
      );
      if (alt < -0.1) continue; // below horizon
      final pos = projection.project(alt, az);
      if (pos != null) projected[star] = pos;
    }

    // Constellation lines
    final linePaint = Paint()
      ..color = const Color(0x26FFFFFF) // ~15% white
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    for (final con in constellations) {
      for (final line in con.lines) {
        if (line.length < 2) continue;
        final s1 = starById[line[0]];
        final s2 = starById[line[1]];
        if (s1 == null || s2 == null) continue;
        final p1 = projected[s1];
        final p2 = projected[s2];
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }

    // Stars
    for (final entry in projected.entries) {
      final star = entry.key;
      final pos = entry.value;
      final radius = _radius(star.mag);
      final opacity = _opacity(star.mag);

      // Glow for bright stars
      if (star.mag < 1.5) {
        canvas.drawCircle(
          pos,
          radius * 2.5,
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, opacity * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }
  }

  /// Star dot radius in logical pixels. Brighter (lower mag) → larger.
  double _radius(double mag) => max(0.5, 3.0 - mag * 0.35);

  /// Star opacity. Brighter (lower mag) → more opaque.
  double _opacity(double mag) => (1.0 - mag / 8.0).clamp(0.15, 1.0);

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.lst != lst ||
      old.projection.centerAz != projection.centerAz ||
      old.projection.centerAlt != projection.centerAlt;
}
```

- [ ] **Step 2: Run the full test suite to ensure nothing broke**

```bash
flutter test
```

Expected: all previously passing tests still pass.

- [ ] **Step 3: Commit**

```bash
git add lib/stars/sky_painter.dart
git commit -m "feat: SkyPainter CustomPainter — stars, constellation lines, glow for bright stars"
```

---

## Task 7: StarsScreen

**Files:**
- Create: `lib/screens/stars_screen.dart`
- Create: `test/stars_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/stars_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/screens/stars_screen.dart';
import 'package:awe/stars/star.dart';
import 'package:awe/stars/constellation.dart';
import 'package:awe/stars/star_catalog.dart';
import 'package:awe/stars/sky_orientation.dart';

void main() {
  final catalog = StarCatalog(
    stars: [
      const Star(id: 32349, ra: 1.7679, dec: -0.2911, mag: -1.46, name: 'Sirius'),
      const Star(id: 11767, ra: 0.6637, dec: 1.5580, mag: 1.97, name: 'Polaris'),
    ],
    constellations: [
      const Constellation(name: 'Test', lines: [[32349, 11767]]),
    ],
  );

  testWidgets('StarsScreen renders without crashing', (tester) async {
    final orientation = FakeSkyOrientationSource();
    await tester.pumpWidget(MaterialApp(
      home: StarsScreen(
        catalog: catalog,
        orientationSource: orientation,
        observerLat: 52.0 * 3.14159 / 180,
        observerLng: 0.0,
      ),
    ));
    await tester.pump(Duration.zero);
    expect(find.byType(StarsScreen), findsOneWidget);
    orientation.dispose();
  });

  testWidgets('StarsScreen repaints when orientation emits', (tester) async {
    final orientation = FakeSkyOrientationSource();
    await tester.pumpWidget(MaterialApp(
      home: StarsScreen(
        catalog: catalog,
        orientationSource: orientation,
        observerLat: 52.0 * 3.14159 / 180,
        observerLng: 0.0,
      ),
    ));
    orientation.emit(const SkyOrientation(azimuth: 1.0, altitude: 0.5));
    await tester.pump();
    expect(find.byType(CustomPaint), findsOneWidget);
    orientation.dispose();
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
flutter test test/stars_screen_test.dart
```

Expected: compilation error — `StarsScreen` not found.

- [ ] **Step 3: Create lib/screens/stars_screen.dart**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../stars/star_catalog.dart';
import '../stars/sky_orientation.dart';
import '../stars/sky_projection.dart';
import '../stars/sky_painter.dart';
import '../stars/astronomy.dart';

class StarsScreen extends StatefulWidget {
  final StarCatalog catalog;
  final SkyOrientationSource orientationSource;
  final double? observerLat; // radians; if null, fetched via GPS
  final double? observerLng; // radians; if null, fetched via GPS

  const StarsScreen({
    super.key,
    required this.catalog,
    required this.orientationSource,
    this.observerLat,
    this.observerLng,
  });

  @override
  State<StarsScreen> createState() => _StarsScreenState();
}

class _StarsScreenState extends State<StarsScreen> {
  SkyOrientation _orientation = const SkyOrientation(azimuth: 0, altitude: 0);
  double _latRad = 0.0;
  double _lngRad = 0.0;
  bool _locationReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.orientationSource.stream.listen(_onOrientation);
    _initLocation();
  }

  void _onOrientation(SkyOrientation o) {
    if (mounted) setState(() => _orientation = o);
  }

  Future<void> _initLocation() async {
    if (widget.observerLat != null && widget.observerLng != null) {
      setState(() {
        _latRad = widget.observerLat!;
        _lngRad = widget.observerLng!;
        _locationReady = true;
      });
      return;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission required.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latRad = pos.latitude * pi / 180;
          _lngRad = pos.longitude * pi / 180;
          _locationReady = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not get location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white70)),
        ),
      );
    }

    if (!_locationReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final lst = localSiderealTime(_lngRad, DateTime.now().toUtc());
          final projection = SkyProjection(
            centerAz: _orientation.azimuth,
            centerAlt: _orientation.altitude,
            fovRadians: 35 * pi / 180, // 35° half-FOV
            screenSize: size,
          );
          final painter = SkyPainter(
            stars: widget.catalog.starsVisibleToNakedEye(),
            constellations: widget.catalog.constellations,
            starById: {for (final s in widget.catalog.stars) s.id: s},
            observerLat: _latRad,
            lst: lst,
            projection: projection,
          );
          return CustomPaint(painter: painter, size: size);
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.orientationSource.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

```bash
flutter test test/stars_screen_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/stars_screen.dart test/stars_screen_test.dart
git commit -m "feat: StarsScreen wires catalog + orientation + painter, handles GPS permissions"
```

---

## Task 8: Hub screen integration

**Files:**
- Modify: `lib/screens/hub_screen.dart`

- [ ] **Step 1: Update the Stars Simulation tile in hub_screen.dart**

In `lib/screens/hub_screen.dart`, add the import at the top:
```dart
import '../stars/star_catalog.dart';
import '../stars/sky_orientation.dart';
import 'stars_screen.dart';
```

Change the Stars Simulation tile (currently `onTap: null, muted: true`) to:

```dart
_HubTile(
  label: 'Stars\nSimulation',
  sublabel: 'The Sky',
  icon: Icons.scatter_plot,
  onTap: () async {
    final catalog = await StarCatalog.load(DefaultAssetBundle.of(context));
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StarsScreen(
          catalog: catalog,
          orientationSource: RealSkyOrientationSource(),
        ),
      ),
    );
  },
),
```

Remove `muted: true` from that tile (or set `muted: false`).

- [ ] **Step 2: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/hub_screen.dart
git commit -m "feat: enable Stars Simulation tile — navigates to live StarsScreen"
```

---

## Task 9: On-device smoke test

This task cannot be run by a code agent — it requires a physical iOS or Android device.

- [ ] **Step 1: Build for iOS or Android**

```bash
flutter run -d <device-id>
```

Get device IDs with: `flutter devices`

- [ ] **Step 2: Verify Stars Simulation tile is tappable on HubScreen**

Tap the tile — it should navigate to a black screen with a loading spinner while GPS is acquired.

- [ ] **Step 3: Accept location permission when prompted**

After permission is granted, stars should appear on screen.

- [ ] **Step 4: Verify star rendering**

- Stars should be visible as white dots on a black background.
- Brighter stars (Sirius, Vega, Betelgeuse) should be larger and brighter.
- Constellation lines should appear as faint white lines connecting stars.

- [ ] **Step 5: Verify gyroscope tracking**

- Slowly pan the phone left/right → stars should scroll across the screen.
- Tilt up → stars near zenith should come into view.
- The view should feel continuous and smooth.

- [ ] **Step 6: Final commit and push**

```bash
git add -A
git commit -m "chore: star viewer complete and smoke-tested on device"
```

---

## Known Limitations (future work)

- **Magnetic declination**: The compass gives magnetic north, not true north. A small offset (varies by location) means stars are slightly misaligned. Fix: apply declination correction from `geolocator`'s `GeoMagneticField` or a lookup table.
- **Tilt compensation**: The azimuth is uncompensated for phone tilt, so when the phone is tilted steeply the heading can drift. Fix: full 3-axis magnetometer + accelerometer fusion.
- **Gyroscope smoothing**: Adding gyroscope integration between compass samples would reduce jitter.
- **Star names overlay**: Tap a star to show its name and magnitude.
- **Constellation labels**: Text overlays at constellation centroids.
