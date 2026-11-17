#!/usr/bin/env python3
"""Draw a blocky backdrop for preview.png, so the committed previews carry no
third-party wallpaper.

    backdrop.py night out.png   dirt behind the old menus, at 25% light
    backdrop.py day   out.png   sky over a row of grass blocks

Each block is a 16x16 grid of random shades, seeded so the output never
changes between runs. Needs ImageMagick (magick) on PATH.
"""
import random, subprocess, sys, tempfile, os

W, H = 2560, 1440
PX = 20            # screen pixels per texel
BLOCK = 16 * PX    # one block on screen

mode, out = sys.argv[1], sys.argv[2]
rng = random.Random(1709)  # fixed seed: same picture every run

DIRT = [(134, 96, 67), (121, 85, 58), (150, 108, 74), (89, 61, 41), (185, 133, 92)]
DIRT_W = [40, 30, 15, 10, 5]
GRASS = [(127, 178, 56), (110, 160, 46), (143, 196, 70), (98, 145, 40)]

def dim(c, f):
    return tuple(int(v * f) for v in c)

def ppm(pixels, w, h, path):
    with open(path, "wb") as fh:
        fh.write(f"P6 {w} {h} 255\n".encode())
        fh.write(bytes(v for p in pixels for v in p))

tw, th = W // PX, H // PX  # texel canvas
px = []
for y in range(th):
    for x in range(tw):
        if mode == "night":
            px.append(dim(rng.choices(DIRT, DIRT_W)[0], 0.25))
        else:
            ground = th - (BLOCK // PX) * 2      # two rows of blocks at the bottom
            if y < ground:
                t = y / ground                   # sky: deeper blue at the top
                top, bot = (120, 167, 255), (190, 214, 255)
                px.append(tuple(int(a + (b - a) * t) for a, b in zip(top, bot)))
            else:
                row = (y - ground) % 16
                fringe = 3 + (hash((x, (y - ground) // 16)) % 2)
                if (y - ground) < 16 and row < fringe:
                    px.append(rng.choice(GRASS))
                else:
                    px.append(rng.choices(DIRT, DIRT_W)[0])

tmp = tempfile.mkdtemp()
src = os.path.join(tmp, "texels.ppm")
ppm(px, tw, th, src)
subprocess.run(["magick", src, "-filter", "point", "-resize", f"{W}x{H}!", out], check=True)
print(out)
