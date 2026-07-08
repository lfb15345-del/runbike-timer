"""
ランバイクタイマー アプリアイコン一括生成スクリプト
- iOS / Android(通常+アダプティブ前景) / Web(PWA, maskable含む) / favicon を一括出力
- 実行: python tool/generate_icons.py  （プロジェクトルートで実行）
"""
import json
import math
import os
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SS = 4  # スーパーサンプリング倍率
BASE = 1024
SIZE = BASE * SS


def hex2rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

BRAND_GREEN_LIGHT = hex2rgb('3E8E4F')
BRAND_GREEN_DARK = hex2rgb('072016')
WHITE = hex2rgb('FBFBF6')
AMBER = hex2rgb('FFC531')

CONTENT_CENTER = (536, 591)
CANVAS_CENTER = (500, 495)


def make_transform(scale):
    def T(pt):
        x, y = pt
        cx, cy = CONTENT_CENTER
        tx, ty = CANVAS_CENTER
        return ((x - cx) * scale + tx, (y - cy) * scale + ty)
    return T


def make_gradient_bg(size):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    t = np.clip((x + y) / (2 * size), 0, 1)
    c1 = np.array(BRAND_GREEN_LIGHT, dtype=np.float32)
    c2 = np.array(BRAND_GREEN_DARK, dtype=np.float32)
    grad = c1[None, None, :] * (1 - t[..., None]) + c2[None, None, :] * t[..., None]
    cx, cy = size * 0.50, size * 0.48
    dist = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / (size * 0.65)
    glow = np.clip(1 - dist, 0, 1) ** 2.0
    highlight = np.array(BRAND_GREEN_LIGHT, dtype=np.float32) * 0.30
    grad = grad + highlight[None, None, :] * glow[..., None]
    return Image.fromarray(np.clip(grad, 0, 255).astype(np.uint8), mode='RGB')


def rot(pt, origin, deg):
    rad = math.radians(deg)
    ox, oy = origin
    px, py = pt
    dx, dy = px - ox, py - oy
    ca, sa = math.cos(rad), math.sin(rad)
    return (ox + dx * ca - dy * sa, oy + dx * sa + dy * ca)


def pill(draw, p1, p2, width, fill, s):
    a = (p1[0]*s, p1[1]*s)
    b = (p2[0]*s, p2[1]*s)
    draw.line([a, b], fill=fill, width=int(width*s))
    r = width * s / 2
    for pt in (a, b):
        draw.ellipse([pt[0]-r, pt[1]-r, pt[0]+r, pt[1]+r], fill=fill)


def smooth_curve(draw, pts, width, fill, s, steps=40):
    def catmull_rom(p0, p1, p2, p3, t):
        t2, t3 = t*t, t*t*t
        x = 0.5 * ((2*p1[0]) + (-p0[0]+p2[0])*t + (2*p0[0]-5*p1[0]+4*p2[0]-p3[0])*t2 + (-p0[0]+3*p1[0]-3*p2[0]+p3[0])*t3)
        y = 0.5 * ((2*p1[1]) + (-p0[1]+p2[1])*t + (2*p0[1]-5*p1[1]+4*p2[1]-p3[1])*t2 + (-p0[1]+3*p1[1]-3*p2[1]+p3[1])*t3)
        return (x, y)
    ext = [pts[0]] + pts + [pts[-1]]
    curve_pts = []
    for i in range(len(pts) - 1):
        p0, p1, p2, p3 = ext[i], ext[i+1], ext[i+2], ext[i+3]
        for j in range(steps):
            curve_pts.append(catmull_rom(p0, p1, p2, p3, j/steps))
    curve_pts.append(pts[-1])
    for i in range(len(curve_pts) - 1):
        pill(draw, curve_pts[i], curve_pts[i+1], width, fill, s)


def draw_bike(draw, s, scale, with_motion_and_flag=True):
    """ランバイク本体を描く（scaleで全体サイズ調整、safe-zone確保に使う）"""
    T = make_transform(scale)

    if with_motion_and_flag:
        for (yy, x2, length, w, alpha) in [
            (430, 150, 100, 20, 65), (490, 110, 150, 28, 95),
            (555, 130, 118, 22, 70), (615, 165, 82, 16, 45),
        ]:
            x1 = x2 - length
            pill(draw, (x1, yy), (x2, yy - 12), w, WHITE + (alpha,), s)

    RW = T((315, 700)); FW = T((760, 700))
    R = 172 * scale
    for center in (RW, FW):
        cx, cy = center
        draw.ellipse([(cx-R)*s,(cy-R)*s,(cx+R)*s,(cy+R)*s], fill=WHITE)
        inner = R - 46*scale
        draw.ellipse([(cx-inner)*s,(cy-inner)*s,(cx+inner)*s,(cy+inner)*s], fill=BRAND_GREEN_DARK)
        for ang in (0, 30, 60, 90, 120, 150):
            p1 = rot((cx-inner+16*scale, cy), center, ang)
            p2 = rot((cx+inner-16*scale, cy), center, ang)
            draw.line([(p1[0]*s,p1[1]*s),(p2[0]*s,p2[1]*s)], fill=WHITE+(110,), width=int(8*scale*s))
        hub_r = 26 * scale
        draw.ellipse([(cx-hub_r)*s,(cy-hub_r)*s,(cx+hub_r)*s,(cy+hub_r)*s], fill=AMBER)

    frame_curve = [T(p) for p in [
        (315+30, 700-70), (315+140, 700-135), (520, 520), (760-150, 700-160), (760-40, 700-95),
    ]]
    smooth_curve(draw, frame_curve, 58*scale, WHITE, s)

    seat_base = T((315+150, 700-130)); seat_top = T((365, 430))
    pill(draw, seat_base, seat_top, 36*scale, WHITE, s)
    saddle_a = T((365-72, 430+6)); saddle_b = T((365+70, 430-18))
    pill(draw, saddle_a, saddle_b, 46*scale, WHITE, s)

    steer_base = T((760-120, 700-155)); steer_top = T((700, 360))
    pill(draw, steer_base, steer_top, 36*scale, WHITE, s)
    handlebar_a = T((700-64, 360+50)); handlebar_b = T((700+60, 360-42))
    pill(draw, handlebar_a, handlebar_b, 40*scale, WHITE, s)
    for gp in (handlebar_a, handlebar_b):
        r = 24 * scale
        draw.ellipse([(gp[0]-r)*s,(gp[1]-r)*s,(gp[0]+r)*s,(gp[1]+r)*s], fill=AMBER)

    if with_motion_and_flag:
        flag_x0, flag_y0 = 800, 800
        cell = 24
        for row in range(4):
            for col in range(5):
                if (row + col) % 2 == 0:
                    x0 = flag_x0 + col * cell
                    y0 = flag_y0 + row * cell
                    draw.rectangle([x0*s, y0*s, (x0+cell)*s, (y0+cell)*s], fill=WHITE + (190,))


def render_master(transparent, scale):
    s = SIZE / 1000.0
    if transparent:
        img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    else:
        img = make_gradient_bg(SIZE).convert('RGBA')
    draw = ImageDraw.Draw(img, 'RGBA')
    draw_bike(draw, s, scale, with_motion_and_flag=not transparent)
    final = img.resize((BASE, BASE), Image.LANCZOS)
    return final


def save_sized(master, path, size, rgb=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    resized = master.resize((size, size), Image.LANCZOS)
    if rgb:
        resized = resized.convert('RGB')
    resized.save(path, 'PNG')


def main():
    print('マスター画像を生成中...')
    master_solid = render_master(transparent=False, scale=1.16)          # 通常アイコン（背景あり）
    master_fg = render_master(transparent=True, scale=0.92)              # Android前景（透明・余白多め）
    master_maskable = render_master(transparent=False, scale=1.16 * 0.78)  # Web maskable（セーフゾーン確保）

    # ---------- iOS ----------
    ios_dir = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    with open(os.path.join(ios_dir, 'Contents.json'), encoding='utf-8') as f:
        manifest = json.load(f)
    seen = set()
    for entry in manifest['images']:
        size_str = entry['size'].split('x')[0]
        scale_str = entry['scale'].replace('x', '')
        px = round(float(size_str) * float(scale_str))
        fname = entry['filename']
        if fname in seen:
            continue
        seen.add(fname)
        save_sized(master_solid, os.path.join(ios_dir, fname), px, rgb=True)
        print(f'  iOS {fname} -> {px}x{px}')

    # ---------- Android 通常アイコン ----------
    android_res = os.path.join(ROOT, 'android/app/src/main/res')
    for density, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        save_sized(master_solid, os.path.join(android_res, f'mipmap-{density}/ic_launcher.png'), px, rgb=True)
        print(f'  Android mipmap-{density}/ic_launcher.png -> {px}x{px}')

    # ---------- Android アダプティブ前景（透明・RGBA） ----------
    for density, px in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216), ('xxhdpi', 324), ('xxxhdpi', 432)]:
        save_sized(master_fg, os.path.join(android_res, f'drawable-{density}/ic_launcher_foreground.png'), px, rgb=False)
        print(f'  Android drawable-{density}/ic_launcher_foreground.png -> {px}x{px}')

    # ---------- Web ----------
    web_icons = os.path.join(ROOT, 'web/icons')
    save_sized(master_solid, os.path.join(web_icons, 'Icon-192.png'), 192, rgb=True)
    save_sized(master_solid, os.path.join(web_icons, 'Icon-512.png'), 512, rgb=True)
    save_sized(master_maskable, os.path.join(web_icons, 'Icon-maskable-192.png'), 192, rgb=True)
    save_sized(master_maskable, os.path.join(web_icons, 'Icon-maskable-512.png'), 512, rgb=True)
    save_sized(master_solid, os.path.join(ROOT, 'web/favicon.png'), 64, rgb=True)
    print('  Web icons + favicon 完了')

    print('\n全アイコン生成完了！')


if __name__ == '__main__':
    main()
