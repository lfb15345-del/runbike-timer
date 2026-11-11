import 'package:flutter/material.dart';

/// アプリ全体のテーマ定義
/// 色・角丸・ボタン・文字のスタイルはすべてここに集約する。
///
/// デザインの考え方（v1.1〜）:
/// ・屋外の日なたでも読めるよう、「墨色 × 白 × 黄緑」の強いコントラストだけで組む
/// ・影・グラデーション・光の粒などの飾りは使わない。色の面と大きな数字で状態を伝える
/// ・数字と英字見出しは、スポーツ計時で使われる細身の斜体（Barlow Condensed）
class AppTheme {
  AppTheme._(); // インスタンス化させない

  /// 墨色（わずかに緑がかった黒）。文字・主要ボタン・休憩中の背景
  static const Color ink = Color(0xFF0F1512);

  /// 紙色（設定画面などの背景）
  static const Color paper = Color(0xFFF4F5EF);

  /// アクセントの黄緑（ロゴの前輪と同じ色）。走行中の背景・選択中の印
  static const Color volt = Color(0xFFC8F23A);

  /// ラスト3秒の警告色
  static const Color signal = Color(0xFFFF5A1F);

  /// 罫線・枠線
  static const Color line = Color(0xFFD9DCD0);

  /// 補助テキスト（ラベル・注記）
  static const Color muted = Color(0xFF687065);

  /// 白地の上で使う緑（自己ベストなど「良い結果」の文字色。黄緑は白地だと読めないため）
  static const Color deepGreen = Color(0xFF1B7A43);

  /// 録画中・削除などの赤
  static const Color goRed = Color(0xFFE5342A);
  static const Color recordRed = goRed;

  /// 数字・英字見出し用フォント
  static const String displayFont = 'Barlow Condensed';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF55701F),
    ).copyWith(
      primary: ink,
      onPrimary: Colors.white,
      secondary: ink,
      onSecondary: Colors.white,
      surface: paper,
      onSurface: ink,
      surfaceTint: Colors.transparent,
      outline: const Color(0xFFAEB3A4),
      outlineVariant: line,
      error: goRed,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Noto Sans JP',
      scaffoldBackgroundColor: paper,

      // メインボタン: 墨色ベタ・影なし
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: line,
          disabledForegroundColor: muted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Noto Sans JP',
          ),
        ),
      ),

      // 枠線ボタン
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: ink, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Noto Sans JP',
          ),
        ),
      ),

      // 選択チップ（コース設定の路面・天気など）
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: volt,
        checkmarkColor: ink,
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(color: ink, fontFamily: 'Noto Sans JP'),
        secondaryLabelStyle:
            const TextStyle(color: ink, fontFamily: 'Noto Sans JP'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // カード: 白地 + 細い枠線（影なし）
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
      ),

      // スイッチ: ONは墨色の土台に黄緑のつまみ
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          return states.contains(WidgetState.selected) ? volt : null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          return states.contains(WidgetState.selected) ? ink : null;
        }),
      ),

      dividerTheme: const DividerThemeData(color: line, thickness: 1),

      // お知らせバー（「記録しました」など）
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Noto Sans JP',
          fontSize: 14,
        ),
        actionTextColor: volt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 下タブバー（白地。選択中は黄緑の座布団）
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: volt,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? ink : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? ink : muted);
        }),
      ),
    );
  }

  /// タイマー表示用の数字スタイル（細身の斜体 + 等幅数字）
  static TextStyle timerStyle({
    required double fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      fontFamily: displayFont,
      fontFamilyFallback: const ['Noto Sans JP'],
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.0,
      color: color,
    );
  }

  /// 英字見出し（READY / GO / REST / FINISH など）用の表示スタイル
  static TextStyle displayStyle({
    required double fontSize,
    Color color = ink,
    double letterSpacing = 1,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      fontFamily: displayFont,
      fontFamilyFallback: const ['Noto Sans JP'],
      height: 1.0,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// 小さな英字ラベル（ROUND 3/8 など）用のスタイル
  static TextStyle labelStyle({
    double fontSize = 15,
    Color color = ink,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      fontFamily: displayFont,
      fontFamilyFallback: const ['Noto Sans JP'],
      height: 1.0,
      color: color,
      letterSpacing: 1.5,
    );
  }
}
