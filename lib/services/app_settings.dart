/// アプリ全体で共有する設定値
/// （これまで MeasureScreen の static 変数だったものを独立させた）
class AppSettings {
  /// Bluetoothスピーカーの音声遅延補正（ms）
  /// 計測タブ・練習タブで共通の値を使う
  static int bluetoothOffsetMs = 0;

  static const int btOffsetStep = 50; // ±ボタン1回の増減量
  static const int btOffsetMax = 500; // 補正の上限
}
