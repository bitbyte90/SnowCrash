#!/usr/bin/env python3
"""Builds a fake "webrips" folder tree for testing the demo without real files.

Usage: python3 make_demo_fixture.py [target_dir]   (default /tmp/snowcrash_fixture)
Needs Pillow; uses ffmpeg (if installed) for the sample videos.
Layout mirrors Bit's first test (DEMO_MVP_SPEC.md §4): each site has Images and Videos.
"""
import os, random, shutil, subprocess, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/snowcrash_fixture"
random.seed(42)

try:
    FONT = ImageFont.truetype("DejaVuSans-Bold.ttf", 44)
    SMALL = ImageFont.truetype("DejaVuSans.ttf", 22)
except OSError:
    FONT = SMALL = ImageFont.load_default()

PALETTES = {
    "aurora": [(10, 20, 60), (20, 200, 150), (120, 60, 200)],
    "cats": [(250, 200, 150), (200, 120, 80), (90, 60, 40)],
    "night": [(5, 5, 25), (40, 40, 110), (230, 230, 255)],
    "sunset": [(255, 120, 60), (200, 50, 100), (40, 20, 80)],
    "forest": [(20, 60, 30), (90, 150, 60), (200, 220, 150)],
    "sea": [(0, 60, 120), (0, 150, 200), (220, 240, 255)],
}


def picture(path, title, palette, w=800, h=600):
    a, b, c = PALETTES[palette]
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):  # vertical gradient
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3)))
    for _ in range(random.randint(3, 9)):  # blobs
        r = random.randint(30, 160)
        x, y = random.randint(0, w), random.randint(0, h)
        col = tuple(min(255, int(c[i] * random.uniform(0.6, 1.1))) for i in range(3))
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)
    d.rectangle([0, h - 70, w, h], fill=(0, 0, 0))
    d.text((24, h - 62), title, fill=(255, 255, 255), font=FONT)
    img.save(path, quality=88)


def pictures(folder, prefix, n, palette):
    os.makedirs(folder, exist_ok=True)
    for i in range(1, n + 1):
        picture(os.path.join(folder, f"{prefix}_{i:03}.jpg"), f"{prefix} {i}", palette)


def video(path, source, seconds=6):
    if not shutil.which("ffmpeg"):
        open(path, "wb").close()
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    vcodec = ["-c:v", "libtheora", "-q:v", "6"] if path.endswith(".ogv") else ["-c:v", "libx264", "-pix_fmt", "yuv420p"]
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "lavfi", "-i", f"{source}=size=640x360:rate=25",
                    "-t", str(seconds), *vcodec, path], check=True)


def touch(path, text="sample"):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


if os.path.exists(ROOT):
    shutil.rmtree(ROOT)
W = os.path.join(ROOT, "Webrips")

a = os.path.join(W, "Aurora Photos")
pictures(os.path.join(a, "Images"), "Aurora", 18, "aurora")
pictures(os.path.join(a, "Images", "2019"), "Night 2019", 130, "night")   # big folder -> cycling canvases
pictures(os.path.join(a, "Images", "2020"), "Sunset 2020", 8, "sunset")
pictures(os.path.join(a, "Images", "Forest Walk"), "Forest", 14, "forest")
video(os.path.join(a, "Videos", "Intro.ogv"), "mandelbrot", 8)
video(os.path.join(a, "Videos", "Timelapse.mp4"), "testsrc2")
video(os.path.join(a, "Videos", "Behind the scenes.mp4"), "smptehdbars")
touch(os.path.join(a, "index.html"), "<html><body>Aurora Photos</body></html>")
touch(os.path.join(a, "style.css"), "body{}")
touch(os.path.join(a, "backup.zip"))
touch(os.path.join(a, "notes.txt"), "Downloaded 2024")

b = os.path.join(W, "Cat Gallery")
pictures(os.path.join(b, "Images"), "Cat", 36, "cats")
video(os.path.join(b, "Videos", "Cat zoomies.mp4"), "testsrc")
touch(os.path.join(b, "index.html"))

c = os.path.join(W, "Old Forum")
for i in range(1, 16):  # 15 subfolders -> hallway overflow
    pictures(os.path.join(c, "Threads", f"Thread {i:02}"), f"Thread {i}", 3, random.choice(list(PALETTES)))

s = os.path.join(W, "Seaside 日本語 ☀")  # odd names must not break anything
pictures(s, "Sea", 10, "sea")
touch(os.path.join(s, "mystery.xyz"))
touch(os.path.join(s, "photo.heic"))  # known image type we can't decode -> Polaroid

f = os.path.join(ROOT, "Films")
video(os.path.join(f, "Night Drive.ogv"), "mandelbrot", 10)
video(os.path.join(f, "Test Card.mp4"), "smptebars")
video(os.path.join(f, "Colour Bars.mp4"), "testsrc2")
print("Fixture ready at", ROOT)
