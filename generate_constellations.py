#!/usr/bin/env python3
import json, urllib.request, os

MODERN_URL = "https://raw.githubusercontent.com/Stellarium/stellarium/master/skycultures/modern/index.json"
OUT = "assets/data/constellations.json"

os.makedirs("assets/data", exist_ok=True)

print("Downloading Stellarium modern sky culture...")
with urllib.request.urlopen(MODERN_URL) as r:
    data = json.load(r)

constellations = {}
for c in data.get("constellations", []):
    con_id = c.get("id", "")
    # Extract 3-letter IAU abbreviation from id like "CON modern Aql"
    parts = con_id.split()
    if len(parts) < 3:
        continue
    name = parts[2]  # e.g. "Aql"

    lines_out = []
    for segment in c.get("lines", []):
        # Each segment is a sequence of HIP IDs forming a connected line
        for i in range(len(segment) - 1):
            h1 = segment[i]
            h2 = segment[i + 1]
            if h1 and h2:
                lines_out.append([h1, h2])

    if lines_out:
        constellations[name] = lines_out

with open(OUT, "w") as f:
    json.dump(constellations, f, separators=(",", ":"))
print(f"Written {len(constellations)} constellations to {OUT}")
