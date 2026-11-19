import 'dart:ui';

/// 端末の言語設定から、アプリで使う言語を決める。
/// 対応: 日本語・英語・繁体字中国語・タイ語・韓国語。それ以外の言語は英語で表示する。
class AppLanguage {
  AppLanguage._();

  static const List<String> supportedCodes = ['ja', 'en', 'zh', 'th', 'ko'];

  /// 起動時に決めた言語（テーマのフォント選びなどで使う）
  static Locale current = const Locale('ja');

  /// 端末の「優先する言語」を上から順に見て、最初に対応しているものを使う
  static Locale resolve(List<Locale>? deviceLocales) {
    for (final locale in deviceLocales ?? const <Locale>[]) {
      final code = locale.languageCode;
      if (!supportedCodes.contains(code)) continue;
      if (code == 'zh') {
        // 中国語は繁体字（台湾・香港向け）で表示する
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      }
      return Locale(code);
    }
    return const Locale('en');
  }

  static bool get isJapanese => current.languageCode == 'ja';

  /// 録画を保存する写真アルバムの名前
  static String get albumName => isJapanese ? 'ランバイクタイマー' : 'Runbike Timer';
}
