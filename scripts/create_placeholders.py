#!/usr/bin/env python3
"""Generate placeholder assets for the Awe Flutter app."""
import os
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).parent.parent
IMAGES_DIR = ROOT / "assets" / "images"
AUDIO_DIR = ROOT / "assets" / "audio"
VIDEO_DIR = ROOT / "assets" / "video"

IMAGES_DIR.mkdir(parents=True, exist_ok=True)
AUDIO_DIR.mkdir(parents=True, exist_ok=True)
VIDEO_DIR.mkdir(parents=True, exist_ok=True)


def create_png(path: Path, width: int, height: int, label: str, color=(10, 10, 20)):
    """Create a minimal PNG file."""
    try:
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new("RGB", (width, height), color)
        draw = ImageDraw.Draw(img)
        draw.text((width // 2 - 20, height // 2 - 10), label, fill=(80, 80, 120))
        img.save(str(path), "PNG")
        print(f"  Created: {path.name}")
        return
    except ImportError:
        pass

    # Fallback: write a minimal valid 1x1 PNG
    def make_chunk(chunk_type: bytes, data: bytes) -> bytes:
        length = struct.pack(">I", len(data))
        crc = struct.pack(">I", zlib.crc32(chunk_type + data) & 0xFFFFFFFF)
        return length + chunk_type + data + crc

    # 1x1 dark blue pixel
    signature = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    ihdr = make_chunk(b"IHDR", ihdr_data)
    raw_pixel = bytes([0, color[0], color[1], color[2]])
    compressed = zlib.compress(raw_pixel)
    idat = make_chunk(b"IDAT", compressed)
    iend = make_chunk(b"IEND", b"")

    with open(path, "wb") as f:
        f.write(signature + ihdr + idat + iend)
    print(f"  Created (minimal PNG): {path.name}")


def create_stub_audio(path: Path):
    """Create a minimal valid MP3 stub (silence frame)."""
    # Minimal MP3 frame header: MPEG1, Layer3, 128kbps, 44100Hz, stereo
    # Frame sync + header bytes
    mp3_header = bytes([0xFF, 0xFB, 0x90, 0x00])
    # 417 bytes of silence (one frame at 128kbps/44100Hz)
    frame_data = bytes(417)
    with open(path, "wb") as f:
        f.write(mp3_header + frame_data)
    print(f"  Created stub: {path.name}")


def create_stub_video(path: Path):
    """Create a stub MP4 file (not a valid video, just a placeholder)."""
    # Write empty file as stub
    path.write_bytes(b"")
    print(f"  Created stub: {path.name}")


print("Generating placeholder images...")
for i in range(1, 23):
    label = str(i)
    num = str(i).zfill(2)
    # Vary darkness/hue slightly for each image
    r = 5 + (i * 3 % 20)
    g = 5 + (i * 2 % 15)
    b = 15 + (i * 4 % 30)
    create_png(IMAGES_DIR / f"montage_{num}.png", 1920, 1080, label, (r, g, b))

create_png(IMAGES_DIR / "closing_bg.png", 1920, 1080, "bg", (5, 5, 10))

print("\nGenerating placeholder audio...")
create_stub_audio(AUDIO_DIR / "ambient.mp3")

print("\nGenerating placeholder video...")
create_stub_video(VIDEO_DIR / "milky_way.mp4")

print("\nDone! All placeholder assets created.")
