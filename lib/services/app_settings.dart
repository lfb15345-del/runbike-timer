import 'package:flutter/foundation.dart';

/// アプリ全体で共有する設定値
/// （これまで MeasureScreen の static 変数だったものを独立させた）
class AppSettings {
  /// いま表示中の下タブ（0=計測, 1=練習, 2=解析, 3=コース）
  /// カメラは同時に1画面しか使えないので、タブを離れた画面はカメラを手放す
  static final ValueNotifier<int> currentTab = ValueNotifier<int>(0);

  /// Bluetoothスピーカーの音声遅延補正（ms）
  /// 計測タブ・練習タブで共通の値を使う
  static int bluetoothOffsetMs = 0;

  static const int btOffsetStep = 50; // ±ボタン1回の増減量
  static const int btOffsetMax = 500; // 補正の上限
}
