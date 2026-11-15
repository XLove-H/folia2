"""按 folia 官方 public/icon.svg 的几何数据生成 iOS App 图标。

官方 SVG：512x512，黑色圆角方块 + 由 4 个圆角矩形拼成的白色大写 F：
  rect(141, 86, 88,156)  rect(241, 86,150, 84)
  rect(141,254,200, 80)  rect(141,346, 88, 80)
本脚本按同一几何关系放大重绘到 1024，再下采样出全套尺寸。
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "FoliaIOS" / "Resources" / "Assets.xcassets"
ICONSET = ASSETS / "AppIcon.appiconset"

MASTER = 1024
SCALE = 1.8  # 相对 512 设计稿的放大倍数（1.0 = 原始 2x）

# (x, y, w, h) 设计稿坐标
BLOCKS = [
    (141, 86, 88, 156),
    (241, 86, 150, 84),
    (141, 254, 200, 80),
    (141, 346, 88, 80),
]
RADIUS = 10


def build_master() -> Image.Image:
    img = Image.new("RGB", (MASTER, MASTER), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    xs = [b[0] for b in BLOCKS] + [b[0] + b[2] for b in BLOCKS]
    ys = [b[1] for b in BLOCKS] + [b[1] + b[3] for b in BLOCKS]
    cx = (min(xs) + max(xs)) / 2
    cy = (min(ys) + max(ys)) / 2
    tx = MASTER / 2 - cx * SCALE
    ty = MASTER / 2 - cy * SCALE

    for x, y, w, h in BLOCKS:
        box = (
            x * SCALE + tx,
            y * SCALE + ty,
            (x + w) * SCALE + tx,
            (y + h) * SCALE + ty,
        )
        draw.rounded_rectangle(box, radius=RADIUS * SCALE, fill=(255, 255, 255))
    return img


# (idiom, size, scale)
SPECS = [
    ("iphone", 20, 2), ("iphone", 20, 3),
    ("iphone", 29, 2), ("iphone", 29, 3),
    ("iphone", 40, 2), ("iphone", 40, 3),
    ("iphone", 60, 2), ("iphone", 60, 3),
    ("ipad", 20, 1), ("ipad", 20, 2),
    ("ipad", 29, 1), ("ipad", 29, 2),
    ("ipad", 40, 1), ("ipad", 40, 2),
    ("ipad", 76, 1), ("ipad", 76, 2),
    ("ipad", 83.5, 2),
    ("ios-marketing", 1024, 1),
]


def main() -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)
    master = build_master()

    images = []
    for idiom, size, scale in SPECS:
        px = int(round(size * scale))
        name = f"AppIcon-{idiom}-{str(size).replace('.', '_')}@{scale}x.png"
        master.resize((px, px), Image.LANCZOS).save(ICONSET / name, "PNG", optimize=True)
        images.append({
            "filename": name,
            "idiom": idiom,
            "scale": f"{scale}x",
            "size": f"{size}x{size}",
        })
        print(f"  {name}  {px}x{px}")

    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (ICONSET / "Contents.json").write_text(
        __import__("json").dumps(contents, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    (ASSETS / "Contents.json").write_text(
        __import__("json").dumps({"info": {"author": "xcode", "version": 1}},
                                 indent=2) + "\n",
        encoding="utf-8",
    )

    accent = {
        "colors": [{
            "idiom": "universal",
            "color": {
                "color-space": "srgb",
                "components": {"red": "0.722", "green": "0.655", "blue": "1.000", "alpha": "1.000"},
            },
        }],
        "info": {"author": "xcode", "version": 1},
    }
    accent_dir = ASSETS / "AccentColor.colorset"
    accent_dir.mkdir(parents=True, exist_ok=True)
    (accent_dir / "Contents.json").write_text(
        __import__("json").dumps(accent, indent=2) + "\n", encoding="utf-8"
    )

    master.save(ROOT / "Support" / "icon-preview.png", "PNG")
    print("完成，预览图: Support/icon-preview.png")


if __name__ == "__main__":
    main()
