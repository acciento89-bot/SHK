#!/usr/bin/env python3
import argparse
import json
import math
import os
import struct
import zlib

SIZE = 1024
BG_TOP = (7, 24, 42)
BG_BOTTOM = (9, 55, 66)
MINT = (104, 240, 202)
CYAN = (90, 210, 255)
WHITE = (236, 247, 250)
SOFT = (34, 84, 96)


def clamp(v):
    return max(0, min(255, int(v)))


def canvas():
    data = bytearray(SIZE * SIZE * 3)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        r = BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t
        g = BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t
        b = BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t
        for x in range(SIZE):
            vignette = 1.0 - 0.16 * (((x - SIZE / 2) / (SIZE / 2)) ** 2 + ((y - SIZE / 2) / (SIZE / 2)) ** 2)
            i = (y * SIZE + x) * 3
            data[i] = clamp(r * vignette)
            data[i + 1] = clamp(g * vignette)
            data[i + 2] = clamp(b * vignette)
    return data


def set_pixel(data, x, y, color):
    if 0 <= x < SIZE and 0 <= y < SIZE:
        i = (y * SIZE + x) * 3
        data[i:i + 3] = bytes(color)


def disk(data, cx, cy, radius, color):
    r2 = radius * radius
    x0, x1 = max(0, int(cx - radius)), min(SIZE - 1, int(cx + radius))
    y0, y1 = max(0, int(cy - radius)), min(SIZE - 1, int(cy + radius))
    for y in range(y0, y1 + 1):
        dy2 = (y - cy) * (y - cy)
        for x in range(x0, x1 + 1):
            if (x - cx) * (x - cx) + dy2 <= r2:
                set_pixel(data, x, y, color)


def line(data, x1, y1, x2, y2, width, color):
    dx, dy = x2 - x1, y2 - y1
    steps = max(1, int(max(abs(dx), abs(dy))))
    radius = max(1, width // 2)
    for n in range(steps + 1):
        t = n / steps
        disk(data, x1 + dx * t, y1 + dy * t, radius, color)


def rect(data, x0, y0, x1, y1, color):
    for y in range(max(0, y0), min(SIZE, y1)):
        for x in range(max(0, x0), min(SIZE, x1)):
            set_pixel(data, x, y, color)


def rounded_rect(data, x0, y0, x1, y1, radius, color):
    rect(data, x0 + radius, y0, x1 - radius, y1, color)
    rect(data, x0, y0 + radius, x1, y1 - radius, color)
    for cx, cy in ((x0 + radius, y0 + radius), (x1 - radius - 1, y0 + radius), (x0 + radius, y1 - radius - 1), (x1 - radius - 1, y1 - radius - 1)):
        disk(data, cx, cy, radius, color)


def ring(data, cx, cy, outer, inner, color):
    disk(data, cx, cy, outer, color)
    disk(data, cx, cy, inner, SOFT)


def draw_snowflake(data):
    cx = cy = 512
    disk(data, cx, cy, 205, SOFT)
    for k in range(6):
        a = math.radians(k * 60)
        x2, y2 = cx + math.cos(a) * 235, cy + math.sin(a) * 235
        line(data, cx, cy, x2, y2, 28, MINT)
        for d in (145, 195):
            bx, by = cx + math.cos(a) * d, cy + math.sin(a) * d
            for off in (-38, 38):
                aa = a + math.radians(180 + off)
                line(data, bx, by, bx + math.cos(aa) * 72, by + math.sin(aa) * 72, 18, MINT)
    disk(data, cx, cy, 38, WHITE)


def draw_fan(data):
    cx = cy = 512
    ring(data, cx, cy, 260, 226, CYAN)
    disk(data, cx, cy, 70, WHITE)
    for k in range(3):
        a = math.radians(-90 + k * 120)
        bx, by = cx + math.cos(a) * 150, cy + math.sin(a) * 150
        line(data, cx, cy, bx, by, 70, MINT)
        disk(data, bx, by, 82, MINT)
        aa = a + math.radians(62)
        line(data, bx, by, bx + math.cos(aa) * 118, by + math.sin(aa) * 118, 58, MINT)
    disk(data, cx, cy, 42, BG_TOP)


def draw_radiator(data):
    rounded_rect(data, 245, 300, 780, 715, 44, SOFT)
    for x in (300, 390, 480, 570, 660, 750):
        rounded_rect(data, x - 25, 330, x + 25, 685, 22, MINT)
    line(data, 255, 760, 355, 760, 26, WHITE)
    line(data, 670, 760, 770, 760, 26, WHITE)
    for x in (365, 515, 665):
        pts = [(x, 250), (x - 28, 218), (x + 30, 180), (x, 145)]
        for a, b in zip(pts, pts[1:]):
            line(data, a[0], a[1], b[0], b[1], 18, CYAN)


def draw_pipe(data):
    rounded_rect(data, 220, 250, 765, 780, 58, SOFT)
    line(data, 280, 385, 640, 385, 92, MINT)
    line(data, 640, 385, 640, 690, 92, MINT)
    disk(data, 640, 385, 70, MINT)
    line(data, 245, 385, 310, 385, 28, WHITE)
    line(data, 640, 660, 640, 735, 28, WHITE)
    ring(data, 640, 385, 48, 25, CYAN)


def draw_checklist(data):
    rounded_rect(data, 250, 205, 775, 815, 56, SOFT)
    rounded_rect(data, 350, 160, 675, 255, 38, MINT)
    for y in (355, 505, 655):
        rounded_rect(data, 310, y - 32, 374, y + 32, 14, WHITE)
        line(data, 320, y, 340, y + 20, 14, MINT)
        line(data, 340, y + 20, 378, y - 25, 14, MINT)
        line(data, 430, y, 700, y, 24, CYAN)


def write_png(path, data):
    raw = bytearray()
    stride = SIZE * 3
    for y in range(SIZE):
        raw.append(0)
        raw.extend(data[y * stride:(y + 1) * stride])

    def chunk(kind, payload):
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload) & 0xffffffff)

    png = bytearray(b'\x89PNG\r\n\x1a\n')
    png.extend(chunk(b'IHDR', struct.pack('>IIBBBBB', SIZE, SIZE, 8, 2, 0, 0, 0)))
    png.extend(chunk(b'IDAT', zlib.compress(bytes(raw), 9)))
    png.extend(chunk(b'IEND', b''))
    with open(path, 'wb') as f:
        f.write(png)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--app', required=True, choices=['kaltecalc', 'lueftungscalc', 'heizkoerpercalc', 'rohrcalc', 'anlagencheck'])
    parser.add_argument('--source-dir', required=True)
    args = parser.parse_args()

    data = canvas()
    drawers = {
        'kaltecalc': draw_snowflake,
        'lueftungscalc': draw_fan,
        'heizkoerpercalc': draw_radiator,
        'rohrcalc': draw_pipe,
        'anlagencheck': draw_checklist,
    }
    drawers[args.app](data)

    assets = os.path.join(args.source_dir, 'Assets.xcassets')
    appicon = os.path.join(assets, 'AppIcon.appiconset')
    os.makedirs(appicon, exist_ok=True)

    with open(os.path.join(assets, 'Contents.json'), 'w', encoding='utf-8') as f:
        json.dump({'info': {'author': 'xcode', 'version': 1}}, f, indent=2)
        f.write('\n')

    with open(os.path.join(appicon, 'Contents.json'), 'w', encoding='utf-8') as f:
        json.dump({
            'images': [{
                'filename': 'AppIcon-1024.png',
                'idiom': 'universal',
                'platform': 'ios',
                'size': '1024x1024'
            }],
            'info': {'author': 'xcode', 'version': 1}
        }, f, indent=2)
        f.write('\n')

    output = os.path.join(appicon, 'AppIcon-1024.png')
    write_png(output, data)
    print(output)


if __name__ == '__main__':
    main()
