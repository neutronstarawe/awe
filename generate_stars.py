#!/usr/bin/env python3
import csv, json, urllib.request, os

URL = "https://raw.githubusercontent.com/astronexus/HYG-Database/main/hyg/CURRENT/hygdata_v41.csv"
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
