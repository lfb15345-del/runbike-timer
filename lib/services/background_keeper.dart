import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 計測中・練習中に「別のアプリを開いても止まらない」ようにする係。
///
/// スマホは、画面に出ていないアプリをすぐ止めてしまう。それを防ぐために
/// ・Android: 「タイマーが動いています」という通知を出して、動かし続ける許可をもらう
/// ・iPhone : 何もしない。Apple の審査で「裏で音を鳴らす設定」が認められなかったため、
///            別のアプリを開くとスマホ側に止められる（練習は止められた時点で一時停止になる）
/// 計測・練習が終わったら必ず stop() を呼んで元に戻す。
class BackgroundKeeper {
  static const MethodChannel _channel = MethodChannel('runbike/background');
  static bool _active = false;

  /// アプリ起動時に1回呼ぶ: 音の鳴らし方の基本設定
  /// ・ほかのアプリの音と重ねて鳴らせるようにする（割り込まれて止まらない）
  /// ・iPhoneではマナーモードでも鳴らせる種類（playback）にする
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('音声設定エラー: $e');
    }
  }

  /// 計測・練習のスタート時に呼ぶ
  /// [title] [text] は Android の通知に出す文字（端末の言語に翻訳済みのもの）
  static Future<void> start(String title, String text) async {
    if (kIsWeb || _active) return;
    _active = true;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod<void>(
            'start', <String, String>{'title': title, 'text': text});
      }
    } catch (e) {
      debugPrint('バックグラウンド維持の開始エラー: $e');
    }
  }

  /// 計測・練習の終了・中止時に呼ぶ
  static Future<void> stop() async {
    if (kIsWeb || !_active) return;
    _active = false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod<void>('stop');
      }
    } catch (e) {
      debugPrint('バックグラウンド維持の終了エラー: $e');
    }
  }
}
