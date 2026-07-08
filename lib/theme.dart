import 'package:flutter/material.dart';

/// アプリ全体のテーマ定義
/// 各画面でバラバラに指定していた色・角丸・ボタンスタイルをここに集約
class AppTheme {
  AppTheme._(); // インスタンス化させない

  /// ブランドカラー（深めのグリーン = 芝生・コースのイメージ）
  static const Color brandGreen = Color(0xFF2E7D32);

  /// アクションカラー
  static const Color goRed = Color(0xFFD32F2F); // ゴールボタン
  static const Color recordRed = Color(0xFFC62828); // 録画表示

  /// アプリアイコンと共通のアクセントカラー（ホイールハブ・グリップ・CTAボタン等）
  static const Color accentAmber = Color(0xFFFFC531);

  /// 起動画面・アイコンで使うブランドグラデーション（左上=明るいグリーン→右下=深緑）
  static const List<Color> brandGradient = [
    Color(0xFF3E8E4F),
    Color(0xFF072016),
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: brandGreen);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Noto Sans JP',

      // メインボタン: 角丸16・太字を全画面で統一
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Noto Sans JP',
          ),
        ),
      ),

      // 選択チップ（スタート音・BGM選択）
      chipTheme: ChipThemeData(
        selectedColor: brandGreen,
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // 下タブバー
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: brandGreen.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? brandGreen : Colors.grey[700],
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? brandGreen : Colors.grey[600],
          );
        }),
      ),
    );
  }

  /// タイマー表示用の数字スタイル（等幅数字でチラつき防止）
  static TextStyle timerStyle({
    required double fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    );
  }
}
