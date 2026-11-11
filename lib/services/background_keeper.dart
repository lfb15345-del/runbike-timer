import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 計測中・練習中に「別のアプリを開いても止まらない」ようにする係。
///
/// スマホは、画面に出ていないアプリをすぐ止めてしまう。それを防ぐために
/// ・Android: 「タイマーが動いています」という通知を出して、動かし続ける許可をもらう
/// ・iPhone : 無音の音声を流し続ける（音楽アプリが裏で鳴り続けるのと同じ扱いになる）
/// 計測・練習が終わったら必ず stop() を呼んで元に戻す。
class BackgroundKeeper {
  static const MethodChannel _channel = MethodChannel('runbike/background');
  static AudioPlayer? _silentPlayer;
  static bool _active = false;

  /// アプリ起動時に1回呼ぶ: 音の鳴らし方の基本設定
  /// ・ほかのアプリの音と重ねて鳴らせるようにする（割り込まれて止まらない）
  /// ・iPhoneでは裏に回っても鳴らせる種類（playback）にする
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
  static Future<void> start() async {
    if (kIsWeb || _active) return;
    _active = true;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod<void>('start');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final player = _silentPlayer ??= AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('sounds/silence.wav'));
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
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _silentPlayer?.stop();
      }
    } catch (e) {
      debugPrint('バックグラウンド維持の終了エラー: $e');
    }
  }
}
