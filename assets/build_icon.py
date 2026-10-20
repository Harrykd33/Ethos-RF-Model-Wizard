"""Generate the original monochrome Rotorflight category mask (standard library only)."""
from pathlib import Path
import math
import struct
import zlib

SIZE = 64
LINES = ((8, 10, 56, 10), (32, 5, 32, 22), (20, 32, 7, 24),
         (7, 17, 7, 30), (2, 24, 12, 24), (22, 39, 20, 47),
         (39, 39, 42, 47), (15, 47, 51, 47), (15, 47, 12, 44))


def near_line(x, y, line):
    ax, ay, bx, by = line
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - ax - t * dx, y - ay - t * dy) <= 1.5


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def main():
    rows = bytearray()
    for y in range(SIZE):
        rows.append(0)
        for x in range(SIZE):
            ellipse = ((x - 33) / 13) ** 2 + ((y - 31) / 11) ** 2
            on = 0.75 <= ellipse <= 1.25 or any(near_line(x, y, line) for line in LINES)
            rows.append(0 if on else 255)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 0, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(rows))) + chunk(b"IEND", b"")
    target = Path(__file__).resolve().parents[1] / "rotorflight-model-wizard/icon.png"
    target.write_bytes(png)
    print(target)


if __name__ == "__main__":
    main()
