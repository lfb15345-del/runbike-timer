import 'dart:math';

/// スタート音の定義（1音 = ファイル + オフセット + 表示名）
/// これまで計測画面と練習画面に別々に書かれていた定義をここに一元化
class StartSound {
  final String key; // DB保存用の識別子
  final String label; // 画面に表示する名前
  final String? assetPath; // null = サイレント（音なし）
  final int offsetMs; // 音声再生開始からGO!までの時間

  const StartSound({
    required this.key,
    required this.label,
    this.assetPath,
    required this.offsetMs,
  });

  /// Web版（Web Audio API）用のファイル名（例: start02.mp3）
  String? get webFilename => assetPath?.replaceFirst('sounds/', '');
}

/// アプリで使う全スタート音のカタログ
class SoundConfig {
  static const silent = StartSound(
    key: 'silent',
    label: 'サイレント',
    assetPath: null,
    offsetMs: 0,
  );
  static const basic = StartSound(
    key: 'basic',
    label: '基本',
    assetPath: 'sounds/start02.mp3',
    offsetMs: 10600,
  );
  static const finalRace = StartSound(
    key: 'final',
    label: '決勝',
    assetPath: 'sounds/start01.mp3',
    offsetMs: 15500,
  );
  static const semiFinal = StartSound(
    key: 'semi',
    label: '準決勝',
    assetPath: 'sounds/start03.mp3',
    offsetMs: 20050,
  );

  /// BMX式ランダムスタート（UCIルールのゲート合図: ピッ・ピッ・ピッ・ピーー）
  /// 画面では1つのボタン。実際に鳴らす音は、待ち時間の違う6種類から毎回ランダムに選ぶ
  /// （ここの assetPath / offsetMs は代表値。鳴らすときは forPlay() で選び直す）
  static const bmx = StartSound(
    key: 'bmx',
    label: 'BMX',
    assetPath: 'sounds/bmx_1.wav',
    offsetMs: 5084,
  );

  /// BMXの音の種類（ファイル名と、再生開始から「ピーー」が鳴り始めるまでの時間）
  /// 待ち時間: 1.5秒 + ランダム0.1〜2.7秒（UCIルール）→ ピッ(0) ピッ(120) ピッ(240) ピーー(360ms〜2.25秒)
  static const bmxVariants = [
    StartSound(key: 'bmx', label: 'BMX', assetPath: 'sounds/bmx_1.wav', offsetMs: 5084),
    StartSound(key: 'bmx', label: 'BMX', assetPath: 'sounds/bmx_2.wav', offsetMs: 5584),
    StartSound(key: 'bmx', label: 'BMX', assetPath: 'sounds/bmx_3.wav', offsetMs: 6084),
    StartSound(key: 'bmx', label: 'BMX', assetPath: 'sounds/bmx_4.wav', offsetMs: 6584),
    StartSound(key: 'bmx', label: 'BMX', assetPath: 'sounds/bmx_5.wav', offsetMs: 7184),
    StartSound(key: 'bmx', label: 'BMX', assetPath: 'sounds/bmx_6.wav', offsetMs: 7684),
  ];

  static final Random _random = Random();

  /// 実際に鳴らす音を決める（BMXのときだけ、毎回ランダムに1つ選ぶ）
  static StartSound forPlay(StartSound sound) => sound.key == bmx.key
      ? bmxVariants[_random.nextInt(bmxVariants.length)]
      : sound;

  /// 画面に並べる順
  static const all = [silent, basic, finalRace, semiFinal, bmx];

  /// 先読みしておく音（BMXの全種類を含む）
  static List<StartSound> get allFiles => [
        ...all.where((s) => s.key != bmx.key),
        ...bmxVariants,
      ];

  /// key から StartSound を引く（見つからなければ基本音）
  static StartSound byKey(String key) =>
      all.firstWhere((s) => s.key == key, orElse: () => basic);
}

/// 計測中に流すBGM（走行の疾走感演出用）の定義
/// 曲はいずれも DOVA-SYNDROME のフリー素材（商用利用OK・クレジット不要）
class MeasureBgm {
  final String key;
  final String label;
  final String? filename; // assets/sounds/ 直下のファイル名。null = BGMなし

  const MeasureBgm({required this.key, required this.label, this.filename});
}

/// 計測中BGMのカタログ
class MeasureBgmConfig {
  static const none = MeasureBgm(key: 'none', label: 'なし', filename: null);
  static const speed =
      MeasureBgm(key: 'speed', label: 'スピード', filename: 'upbeat.mp3');
  static const rock =
      MeasureBgm(key: 'rock', label: 'ロック', filename: 'bgm_rock.mp3');
  static const bit8 =
      MeasureBgm(key: '8bit', label: '8ビット', filename: 'bgm_8bit.mp3');

  /// 画面に並べる順
  static const all = [none, speed, rock, bit8];
}
