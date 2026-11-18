#!/usr/bin/env python3
"""Generate a branded ClickFlow Windows .ico using only Python's standard library.

The ICO contains 16, 32, 48, 64, and 256 px PNG icons. No external graphic
runtime or font files are required in the release workflow.
"""
from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


def inside_rounded(x: float, y: float) -> bool:
    left, top, right, bottom, radius = .025, .025, .975, .975, .245
    if not (left <= x <= right and top <= y <= bottom):
        return False
    cx = min(max(x, left + radius), right - radius)
    cy = min(max(y, top + radius), bottom - radius)
    return (x-cx)**2 + (y-cy)**2 <= radius**2


def inside_polygon(x: float, y: float, poly: list[tuple[float, float]]) -> bool:
    inside = False
    prevx, prevy = poly[-1]
    for px, py in poly:
        if (py > y) != (prevy > y):
            crossing = (prevx-px) * (y-py) / (prevy-py) + px
            if x < crossing:
                inside = not inside
        prevx, prevy = px, py
    return inside


CURSOR = [(.235, .205), (.265, .79), (.41, .658), (.518, .868),
          (.635, .804), (.521, .603), (.75, .552)]
SPARK_ONE = [(.655, .198), (.703, .15), (.744, .183), (.697, .238)]
SPARK_TWO = [(.76, .28), (.856, .277), (.854, .332), (.758, .338)]


def pixel(x: float, y: float) -> tuple[int, int, int, int]:
    if not inside_rounded(x, y):
        return (0, 0, 0, 0)

    # Dark-to-light blue gradient with a subtle diagonal teal accent.
    strength = .45*x + .55*(1-y)
    r = round(33 + 33*strength)
    g = round(92 + 53*strength)
    b = round(202 + 48*strength)
    if inside_polygon(x, y, CURSOR):
        return (248, 252, 255, 255)
    if inside_polygon(x, y, SPARK_ONE) or inside_polygon(x, y, SPARK_TWO):
        return (126, 241, 217, 255)
    return (r, g, b, 255)


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(
        ">I", zlib.crc32(tag + data) & 0xffffffff
    )


def generate_png(n: int) -> bytes:
    scan = bytearray()
    samples = 3 if n < 128 else 2
    for y in range(n):
        scan.append(0)
        for x in range(n):
            acc = [0., 0., 0., 0.]
            for sy in range(samples):
                for sx in range(samples):
                    xx = (x + (sx+.5)/samples) / n
                    yy = (y + (sy+.5)/samples) / n
                    p = pixel(xx, yy)
                    a = p[3] / 255
                    for k in range(3):
                        acc[k] += p[k] * a
                    acc[3] += a
            area = samples * samples
            alpha = acc[3] / area
            if alpha:
                rgb = [int(max(0, min(255, round(acc[k] / acc[3])))) for k in range(3)]
            else:
                rgb = [0, 0, 0]
            scan.extend(rgb + [round(alpha*255)])
    header = struct.pack(">IIBBBBB", n, n, 8, 6, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", header)
            + png_chunk(b"IDAT", zlib.compress(bytes(scan), level=9))
            + png_chunk(b"IEND", b""))


def generate_ico(path: Path) -> None:
    sizes = [16, 32, 48, 64, 256]
    pngs = [generate_png(n) for n in sizes]
    offset = 6 + 16*len(sizes)
    directory = bytearray(struct.pack("<HHH", 0, 1, len(sizes)))
    for n, data in zip(sizes, pngs):
        directory.extend(struct.pack("<BBBBHHII",
            n if n < 256 else 0, n if n < 256 else 0,
            0, 0, 1, 32, len(data), offset))
        offset += len(data)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(directory) + b"".join(pngs))
    print(f"Generated {path}: {path.stat().st_size} bytes, sizes={sizes}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path,
                        default=Path("webview2-preview/assets/ClickFlow.ico"))
    args = parser.parse_args()
    generate_ico(args.output)
