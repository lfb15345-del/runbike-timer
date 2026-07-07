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

  /// 画面に並べる順
  static const all = [silent, basic, finalRace, semiFinal];

  /// key から StartSound を引く（見つからなければ基本音）
  static StartSound byKey(String key) =>
      all.firstWhere((s) => s.key == key, orElse: () => basic);
}
