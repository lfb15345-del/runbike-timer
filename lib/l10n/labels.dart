import 'app_localizations.dart';

/// 保存データや設定の「キー」を、画面に出す各言語の名前に変える
/// （データベースには日本語の値のまま保存されているので、表示だけ翻訳する）
class Labels {
  Labels._();

  /// スタート音（SoundConfig の key）
  static String startSound(AppLocalizations l, String key) {
    switch (key) {
      case 'silent':
        return l.soundSilent;
      case 'basic':
        return l.soundBasic;
      case 'final':
        return l.soundFinal;
      case 'semi':
        return l.soundSemi;
      case 'bmx':
        return 'BMX';
      default:
        return key;
    }
  }

  /// 計測中BGM（MeasureBgmConfig の key）
  static String measureBgm(AppLocalizations l, String key) {
    switch (key) {
      case 'none':
        return l.bgmNone;
      case 'speed':
        return l.bgmSpeed;
      case 'rock':
        return l.bgmRock;
      case '8bit':
        return l.bgm8bit;
      default:
        return key;
    }
  }

  /// 路面（データベースには日本語で保存）
  static String surface(AppLocalizations l, String value) {
    switch (value) {
      case 'アスファルト':
        return l.surfaceAsphalt;
      case '芝生':
        return l.surfaceGrass;
      case '室内':
        return l.surfaceIndoor;
      case '砂利':
        return l.surfaceGravel;
      case 'その他':
        return l.surfaceOther;
      default:
        return value;
    }
  }

  /// 天気（データベースには日本語で保存）
  static String weather(AppLocalizations l, String value) {
    switch (value) {
      case '晴れ':
        return l.weatherSunny;
      case 'くもり':
        return l.weatherCloudy;
      case '雨':
        return l.weatherRain;
      case '風あり':
        return l.weatherWindy;
      default:
        return value;
    }
  }
}
