"""
App Store 用の「見出し付きスクリーンショット」を作る道具

使い方（runbike_app フォルダで実行。Pillow が必要）:
  1) flutter test tool/screenshots_test.dart   … アプリの実際の画面を撮る
  2) python tool/make_store_images.py         … 見出しを付けて仕上げる

入力: ../appstore_screenshots/latest/*.png （無ければ v1.1.0 を使う）
出力: ../appstore_screenshots/store/ に 1206x2622 のPNG（App Store の 6.3インチ枠用）
見出しの文言は下の SLIDES を書き換える。並び順 = ストアに並べる順。
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, '..', 'appstore_screenshots')
OUT = os.path.join(SHOTS, 'store')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'NotoSansJP-VariableFont_wght.ttf')

W, H = 1206, 2622
INK = (15, 21, 18)
VOLT = (200, 242, 58)
PAPER = (244, 245, 239)
MUTED = (160, 168, 158)

# (元の画像, 見出し(改行は\n), 説明)
SLIDES = [
    ('01_measure.png', 'レースと同じ\nスタート音で計測', '3・2・1・GO! でタイマーが自動スタート'),
    ('02_measure_go.png', 'ゴールは\nタップ1回', '大きな数字で、離れていてもひと目でわかる'),
    ('04_practice_go.png', 'インターバル練習も\nおまかせ', '走る・休むを、画面の色と音でお知らせ'),
    ('05_analysis.png', '自己ベストが\nひと目でわかる', 'お子さんごとに記録を管理・シェア'),
    ('03_practice.png', '練習メニューを\n自由に設定', '走る秒数・休む秒数・本数を調整できる'),
    ('06_course.png', 'コースや天気も\n一緒に記録', 'どこで・どんな条件で走ったかを残せる'),
]


def font(size, weight):
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def fit_font(draw, text, max_w, size, weight, min_size=30):
    """横幅に収まるまで文字を小さくする"""
    while size > min_size:
        f = font(size, weight)
        widest = max(draw.textlength(line, font=f) for line in text.split('\n'))
        if widest <= max_w:
            return f
        size -= 2
    return font(min_size, weight)


def rounded(im, radius):
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], radius, fill=255)
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def make(src, headline, sub, index):
    canvas = Image.new('RGB', (W, H), INK)
    d = ImageDraw.Draw(canvas)
    margin = 90

    # 見出し（白・極太）
    hf = fit_font(d, headline, W - margin * 2, 104, 900)
    y = 170
    for line in headline.split('\n'):
        d.text((margin, y), line, font=hf, fill=PAPER)
        y += int(hf.size * 1.28)

    # 黄緑の短い線
    d.rounded_rectangle([margin, y + 34, margin + 120, y + 46], 6, fill=VOLT)

    # 説明（灰色）
    sf = fit_font(d, sub, W - margin * 2, 44, 500)
    d.text((margin, y + 78), sub, font=sf, fill=MUTED)

    # アプリの画面（角を丸めて下側に置く）
    shot = Image.open(src).convert('RGB')
    shot_w = 860
    shot_h = round(shot.height * shot_w / shot.width)
    shot = shot.resize((shot_w, shot_h), Image.LANCZOS)
    frame_pad = 10
    top = H - shot_h - 140
    left = (W - shot_w) // 2
    d.rounded_rectangle(
        [left - frame_pad, top - frame_pad, left + shot_w + frame_pad, top + shot_h + frame_pad],
        66, fill=(42, 49, 45))
    r = rounded(shot, 56)
    canvas.paste(r, (left, top), r)

    name = f'{index:02d}_{os.path.splitext(os.path.basename(src))[0][3:]}.png'
    canvas.save(os.path.join(OUT, name))
    return name


def main():
    src_dir = os.path.join(SHOTS, 'latest')
    if not os.path.isdir(src_dir):
        src_dir = os.path.join(SHOTS, 'v1.1.0')
    os.makedirs(OUT, exist_ok=True)
    for i, (file, headline, sub) in enumerate(SLIDES, start=1):
        name = make(os.path.join(src_dir, file), headline, sub, i)
        print('作成:', name)
    print('出力先:', os.path.abspath(OUT))


if __name__ == '__main__':
    main()
