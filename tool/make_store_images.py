"""
App Store 用の「見出し付きスクリーンショット」を作る道具（5言語）

使い方（runbike_app フォルダで実行。Pillow が必要。タイ語をきれいに出すには raqm 対応の Pillow）:
  1) flutter test tool/screenshots_test.dart   … アプリの実際の画面を言語ごとに撮る
  2) python tool/make_store_images.py         … 見出しを付けて仕上げる

入力: ../appstore_screenshots/latest/<言語>/*.png
出力: ../appstore_screenshots/store/<言語>/ に 1206x2622 のPNG（App Store の 6.3インチ枠用）
      言語: ja=日本語 / en=英語 / zh=繁体字中国語 / ko=韓国語 / th=タイ語
見出しの文言は下の CAPTIONS を書き換える。並び順 = ストアに並べる順。
日本語以外のフォントは ../shot_fonts/ に置く（無い言語は飛ばす）。
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, '..', 'appstore_screenshots')
OUT = os.path.join(SHOTS, 'store')
JP_FONT = os.path.join(ROOT, 'assets', 'fonts', 'NotoSansJP-VariableFont_wght.ttf')
EXTRA_FONTS = os.path.join(ROOT, '..', 'shot_fonts')

# 言語ごとの見出しフォント
FONTS = {
    'ja': JP_FONT,
    'en': JP_FONT,
    'zh': os.path.join(EXTRA_FONTS, 'NotoSansTC.ttf'),
    'ko': os.path.join(EXTRA_FONTS, 'NotoSansKR.ttf'),
    'th': os.path.join(EXTRA_FONTS, 'NotoSansThai.ttf'),
}

W, H = 1206, 2622
INK = (15, 21, 18)
VOLT = (200, 242, 58)
PAPER = (244, 245, 239)
MUTED = (160, 168, 158)

# ストアに並べる順番（元の画像のファイル名）
ORDER = [
    '01_measure.png',
    '02_measure_go.png',
    '04_practice_go.png',
    '05_analysis.png',
    '03_practice.png',
    '06_course.png',
]

# 言語ごとの (見出し(改行は\n), 説明) 。ORDER と同じ順番
CAPTIONS = {
    'ja': [
        ('レースと同じ\nスタート音で計測', '3・2・1・GO! でタイマーが自動スタート'),
        ('ゴールは\nタップ1回', '大きな数字で、離れていてもひと目でわかる'),
        ('インターバル練習も\nおまかせ', '走る・休むを、画面の色と音でお知らせ'),
        ('自己ベストが\nひと目でわかる', 'お子さんごとに記録を管理・シェア'),
        ('練習メニューを\n自由に設定', '走る秒数・休む秒数・本数を調整できる'),
        ('コースや天気も\n一緒に記録', 'どこで・どんな条件で走ったかを残せる'),
    ],
    'en': [
        ('Race-day\nstart sounds', 'The timer starts itself on 3, 2, 1, GO!'),
        ('One tap\nat the finish', 'Big numbers you can read from across the track'),
        ('Interval training,\nhands-free', 'Screen colors and sounds call ride and rest'),
        ('Personal bests\nat a glance', "Track and share each child's progress"),
        ('Build your own\npractice plan', 'Set ride time, rest time and rounds'),
        ('Log the course\nand the weather', 'Remember where and how every ride went'),
    ],
    'zh': [
        ('和比賽一樣的\n起跑音效', '3、2、1、GO！計時器自動開始'),
        ('終點只要\n點一下', '大大的數字，遠遠就看得清楚'),
        ('間歇訓練\n輕鬆搞定', '用畫面顏色和聲音提示騎乘與休息'),
        ('個人最佳成績\n一目了然', '依孩子分別管理、分享紀錄'),
        ('自由設定\n練習菜單', '可調整騎乘秒數、休息秒數與次數'),
        ('賽道和天氣\n也一起記錄', '留下在哪裡、什麼條件下騎的紀錄'),
    ],
    'ko': [
        ('실제 경기와 같은\n출발 신호음', '3, 2, 1, GO! 타이머가 자동으로 시작'),
        ('결승선에서는\n한 번만 탭', '큰 숫자로 멀리서도 한눈에'),
        ('인터벌 훈련도\n간편하게', '화면 색과 소리로 달리기·휴식을 알려줘요'),
        ('개인 최고 기록을\n한눈에', '아이별로 기록을 관리하고 공유'),
        ('연습 메뉴를\n자유롭게 설정', '달리기·휴식 시간과 횟수를 조절'),
        ('코스와 날씨도\n함께 기록', '어디서, 어떤 조건에서 달렸는지 남겨요'),
    ],
    'th': [
        ('เสียงปล่อยตัว\nเหมือนในสนามแข่ง', 'จับเวลาอัตโนมัติเมื่อ 3, 2, 1, GO!'),
        ('เข้าเส้นชัย\nแตะครั้งเดียว', 'ตัวเลขใหญ่ มองเห็นชัดแม้อยู่ไกล'),
        ('ฝึกอินเทอร์วัล\nได้ง่ายๆ', 'สีหน้าจอและเสียงบอกช่วงปั่นและช่วงพัก'),
        ('สถิติที่ดีที่สุด\nเห็นได้ทันที', 'บันทึกและแชร์ผลของลูกแต่ละคน'),
        ('ตั้งเมนูฝึก\nได้ตามใจ', 'ปรับเวลาปั่น เวลาพัก และจำนวนรอบได้'),
        ('บันทึกสนาม\nและสภาพอากาศ', 'จำได้ว่าปั่นที่ไหน ในสภาพแบบไหน'),
    ],
}


def font(lang, size, weight):
    f = ImageFont.truetype(FONTS[lang], size)
    # 可変フォントの「太さ」だけを指定する（幅などの軸は標準のまま）
    try:
        values = []
        for axis in f.get_variation_axes():
            name = axis.get('name')
            if isinstance(name, bytes):
                name = name.decode('utf-8', 'ignore')
            if name and name.lower().startswith('weight'):
                values.append(max(axis['minimum'], min(axis['maximum'], weight)))
            else:
                values.append(axis['default'])
        f.set_variation_by_axes(values)
    except Exception:
        pass
    return f


def fit_font(draw, lang, text, max_w, size, weight, min_size=30):
    """横幅に収まるまで文字を小さくする"""
    while size > min_size:
        f = font(lang, size, weight)
        widest = max(draw.textlength(line, font=f) for line in text.split('\n'))
        if widest <= max_w:
            return f
        size -= 2
    return font(lang, min_size, weight)


def rounded(im, radius):
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], radius, fill=255)
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def make(lang, src, headline, sub, index, out_dir):
    canvas = Image.new('RGB', (W, H), INK)
    d = ImageDraw.Draw(canvas)
    margin = 90

    # 見出し（白・極太）。タイ語は上下の記号が付くので行の間を少し広げる
    line_gap = 1.42 if lang == 'th' else 1.28
    hf = fit_font(d, lang, headline, W - margin * 2, 104, 900)
    y = 170
    for line in headline.split('\n'):
        d.text((margin, y), line, font=hf, fill=PAPER)
        y += int(hf.size * line_gap)

    # 黄緑の短い線
    d.rounded_rectangle([margin, y + 34, margin + 120, y + 46], 6, fill=VOLT)

    # 説明（灰色）
    sf = fit_font(d, lang, sub, W - margin * 2, 44, 500)
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
    canvas.save(os.path.join(out_dir, name))
    return name


def main():
    for lang, captions in CAPTIONS.items():
        src_dir = os.path.join(SHOTS, 'latest', lang)
        if not os.path.isdir(src_dir):
            print(f'[{lang}] 元の画面がないので飛ばします:', os.path.abspath(src_dir))
            continue
        if not os.path.exists(FONTS[lang]):
            print(f'[{lang}] フォントがないので飛ばします:', os.path.abspath(FONTS[lang]))
            continue
        out_dir = os.path.join(OUT, lang)
        os.makedirs(out_dir, exist_ok=True)
        for i, (file, (headline, sub)) in enumerate(zip(ORDER, captions), start=1):
            name = make(lang, os.path.join(src_dir, file), headline, sub, i, out_dir)
            print(f'[{lang}] 作成:', name)
    print('出力先:', os.path.abspath(OUT))


if __name__ == '__main__':
    main()
