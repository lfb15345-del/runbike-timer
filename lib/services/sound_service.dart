import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import '../constants/sound_config.dart';
import 'web_audio_service.dart';

/// 音声再生の窓口。
/// Web版（Web Audio API）とネイティブ版（audioplayers）の違いを
/// このクラスの中に閉じ込める。画面側は kIsWeb を気にせずここだけ呼べばよい。
class SoundService {
  // ネイティブ版用のプレイヤー（用途別に独立させて同時再生に対応）
  static final AudioPlayer _startPlayer = AudioPlayer();
  static final AudioPlayer _whistlePlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static final AudioPlayer _tickPlayer = AudioPlayer();
  static Timer? _metronomeTimer;

  static const String _whistleAsset = 'sounds/whistle.wav';
  static const String _tickAsset = 'sounds/tick.wav';
  static const String _upbeatAsset = 'sounds/upbeat.wav';

  /// 全スタート音をプリロード（アプリ起動時・画面表示時に呼ぶ）
  static Future<void> preloadStartSounds() async {
    if (kIsWeb) {
      for (final sound in SoundConfig.all) {
        final filename = sound.webFilename;
        if (filename != null) WebAudioService.preloadSound(filename);
      }
    } else {
      for (final sound in SoundConfig.all) {
        final path = sound.assetPath;
        if (path != null) {
          try {
            await _startPlayer.setSource(AssetSource(path));
          } catch (_) {}
        }
      }
      try {
        await _whistlePlayer.setSource(AssetSource(_whistleAsset));
      } catch (_) {}
    }
  }

  /// スタート音（3,2,1,GO!）を再生。サイレントの場合は何もしない
  static void playStartSound(StartSound sound) {
    final path = sound.assetPath;
    if (path == null) return;
    if (kIsWeb) {
      WebAudioService.playSoundBuffer(sound.webFilename!);
    } else {
      // 再生中でも先頭から鳴らし直せるよう、一度止めてから再生
      _startPlayer.stop().then((_) => _startPlayer.play(AssetSource(path)));
    }
  }

  /// ホイッスル音（走行終了の合図）
  static void playWhistle() {
    if (kIsWeb) {
      WebAudioService.playWhistle();
    } else {
      _whistlePlayer.play(AssetSource(_whistleAsset));
    }
  }

  /// メトロノームBGMを開始
  static void startMetronome(int bpm) {
    stopBgm();
    if (kIsWeb) {
      WebAudioService.startMetronome(bpm);
    } else {
      final intervalMs = (60000 / bpm).round();
      _tickPlayer.play(AssetSource(_tickAsset));
      _metronomeTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _tickPlayer.play(AssetSource(_tickAsset)),
      );
    }
  }

  /// アップテンポBGMを開始
  static void startUpbeat() {
    stopBgm();
    if (kIsWeb) {
      WebAudioService.startUpbeat();
    } else {
      _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      _bgmPlayer.play(AssetSource(_upbeatAsset));
    }
  }

  /// BGM（メトロノーム・アップテンポ）だけを停止
  static void stopBgm() {
    if (kIsWeb) {
      WebAudioService.stopMetronome();
      WebAudioService.stopUpbeat();
    } else {
      _metronomeTimer?.cancel();
      _metronomeTimer = null;
      _bgmPlayer.stop();
      _tickPlayer.stop();
    }
  }

  /// 全音声を停止（スタート音・BGM・効果音すべて）
  static void stopAll() {
    if (kIsWeb) {
      WebAudioService.stopAll();
    } else {
      _metronomeTimer?.cancel();
      _metronomeTimer = null;
      _startPlayer.stop();
      _whistlePlayer.stop();
      _bgmPlayer.stop();
      _tickPlayer.stop();
    }
  }
}
