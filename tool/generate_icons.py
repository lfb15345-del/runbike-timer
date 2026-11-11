"""
ランバイクタイマー アプリアイコン一括生成スクリプト（v2: 新ロゴ）

ロゴの考え方:
  ・白い部分 = ランバイクの車体（後輪・フレーム・サドル）
  ・黄緑の部分 = 前輪 + フォーク + ハンドル。ここだけ見ると「ストップウォッチ」
    （輪 = 文字盤、フォーク = 針、ハンドル = 竜頭）になっている
  ・線の太さを1種類にそろえ、影・グラデーション・スピード線は使わない

出力: iOS / Android(通常 + アダプティブ前景) / Web(PWA, maskable) / favicon /
      起動画面のマーク / assets/app_icon.png
実行: python tool/generate_icons.py   （runbike_app フォルダで実行。Pillow が必要）
      python tool/generate_icons.py --preview out.png  （1枚だけ書き出して確認）

※ 形を変えるときは lib/widgets/runbike_mark.dart の数値も同じに直すこと
"""
import json
import os
import sys
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SS = 4  # 4倍で描いて縮小（フチをなめらかにする）

INK = (15, 21, 18)       # 背景の黒（わずかに緑がかった墨色） #0F1512
VOLT = (200, 242, 58)    # アクセントの黄緑 #C8F23A
PAPER = (244, 245, 239)  # 車体の白 #F4F5EF

# ---- ロゴの形（1000x1000 の設計座標） ----
STROKE = 56.0
WHEEL_R = 150.0
REAR_HUB = (275.0, 645.0)
FRONT_HUB = (705.0, 645.0)
HEAD = (600.0, 418.0)        # フレームとフォークの合流点
STEM_TOP = (565.0, 341.0)    # ハンドルの付け根
BAR_A = (501.0, 370.0)       # ハンドル（竜頭）の両端
BAR_B = (629.0, 312.0)
SEAT_BASE = (412.0, 549.0)   # サドルの支柱（フレーム側）
SEAT_TOP = (388.0, 398.0)
SADDLE_A = (316.0, 398.0)
SADDLE_B = (422.0, 398.0)
CONTENT_CENTER = (490.0, 552.0)  # 絵柄の中心（アイコン中央に合わせる点）

# 車体（白）と ストップウォッチ部分（黄緑）
BODY = [
    ('ring', REAR_HUB, WHEEL_R),
    ('line', REAR_HUB, HEAD),
    ('line', SEAT_BASE, SEAT_TOP),
    ('line', SADDLE_A, SADDLE_B),
]
WATCH = [
    ('ring', FRONT_HUB, WHEEL_R),
    ('line', FRONT_HUB, STEM_TOP),
    ('line', BAR_A, BAR_B),
]


def _mask(prims, size, scale):
    """図形リストを白黒マスクとして描く"""
    big = size * SS
    k = big / 1000.0
    mask = Image.new('L', (big, big), 0)
    d = ImageDraw.Draw(mask)

    def tr(p):
        return ((p[0] - CONTENT_CENTER[0]) * scale + 500) * k, \
               ((p[1] - CONTENT_CENTER[1]) * scale + 500) * k

    w = STROKE * scale * k
    for pr in prims:
        if pr[0] == 'ring':
            c = tr(pr[1])
            ro = (pr[2] * scale * k) + w / 2
            ri = (pr[2] * scale * k) - w / 2
            d.ellipse([c[0] - ro, c[1] - ro, c[0] + ro, c[1] + ro], fill=255)
            d.ellipse([c[0] - ri, c[1] - ri, c[0] + ri, c[1] + ri], fill=0)
    for pr in prims:
        if pr[0] == 'line':
            a, b = tr(pr[1]), tr(pr[2])
            d.line([a, b], fill=255, width=int(round(w)))
            for p in (a, b):  # 端を丸くする
                d.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def render(size=1024, scale=1.04, bg=INK, body=PAPER, watch=VOLT):
    """ロゴを描く。bg=None で背景透明（RGBA）"""
    if bg is None:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    else:
        img = Image.new('RGBA', (size, size), bg + (255,))
    for prims, color in ((BODY, body), (WATCH, watch)):
        layer = Image.new('RGBA', (size, size), color + (255,))
        img.paste(layer, (0, 0), _mask(prims, size, scale))
    return img


def save(img, path, size, rgb=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if rgb:
        out = out.convert('RGB')
    out.save(path, 'PNG')


def main():
    if len(sys.argv) >= 3 and sys.argv[1] == '--preview':
        render().convert('RGB').save(sys.argv[2])
        print('プレビューを書き出しました:', sys.argv[2])
        return

    print('マスター画像を生成中...')
    solid = render(scale=1.04)                 # 通常アイコン（背景あり）
    foreground = render(scale=0.96, bg=None)    # Androidアダプティブ前景（透明・余白多め）
    maskable = render(scale=0.84)              # Web maskable（丸く切り抜かれても欠けない）
    launch = render(scale=1.04, bg=None)       # 起動画面のマーク（透明）

    # ---------- アプリ内・ストア用の元画像 ----------
    save(solid, os.path.join(ROOT, 'assets/app_icon.png'), 1024)
    save(foreground, os.path.join(ROOT, 'assets/app_icon_foreground.png'), 1024, rgb=False)

    # ---------- iOS ----------
    ios_dir = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    with open(os.path.join(ios_dir, 'Contents.json'), encoding='utf-8') as f:
        manifest = json.load(f)
    seen = set()
    for entry in manifest['images']:
        px = round(float(entry['size'].split('x')[0]) * float(entry['scale'].replace('x', '')))
        fname = entry['filename']
        if fname in seen:
            continue
        seen.add(fname)
        save(solid, os.path.join(ios_dir, fname), px)
        print(f'  iOS {fname} -> {px}x{px}')

    # iOS 起動画面のマーク
    launch_dir = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
    for name, px in [('LaunchImage.png', 200), ('LaunchImage@2x.png', 400), ('LaunchImage@3x.png', 600)]:
        save(launch, os.path.join(launch_dir, name), px, rgb=False)
    print('  iOS 起動画面マーク 完了')

    # ---------- Android ----------
    res = os.path.join(ROOT, 'android/app/src/main/res')
    for density, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        save(solid, os.path.join(res, f'mipmap-{density}/ic_launcher.png'), px)
    for density, px in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216), ('xxhdpi', 324), ('xxxhdpi', 432)]:
        save(foreground, os.path.join(res, f'drawable-{density}/ic_launcher_foreground.png'), px, rgb=False)
    # Android 起動画面のマーク（画面中央に表示）
    for density, px in [('mdpi', 160), ('hdpi', 240), ('xhdpi', 320), ('xxhdpi', 480), ('xxxhdpi', 640)]:
        save(launch, os.path.join(res, f'drawable-{density}/launch_mark.png'), px, rgb=False)
    print('  Android アイコン + 起動画面マーク 完了')

    # ---------- Web ----------
    web_icons = os.path.join(ROOT, 'web/icons')
    save(solid, os.path.join(web_icons, 'Icon-192.png'), 192)
    save(solid, os.path.join(web_icons, 'Icon-512.png'), 512)
    save(maskable, os.path.join(web_icons, 'Icon-maskable-192.png'), 192)
    save(maskable, os.path.join(web_icons, 'Icon-maskable-512.png'), 512)
    save(solid, os.path.join(ROOT, 'web/favicon.png'), 64)
    print('  Web icons + favicon 完了')

    print('\n全アイコン生成完了！')


if __name__ == '__main__':
    main()
