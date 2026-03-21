import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web版専用: JavaScript の Web Audio API を呼び出す
/// index.html に定義した関数を Dart から globalContext 経由で呼ぶ
/// dart:js_interop_unsafe を使用（@JS アノテーションより安定）
class WebAudioService {
  /// メトロノームのクリック音を1回鳴らす
  static void playTick() {
    try {
      globalContext.callMethod('playTick'.toJS);
    } catch (_) {}
  }

  /// ホイッスル音（エアホーン風）を鳴らす
  static void playWhistle() {
    try {
      globalContext.callMethod('playWhistle'.toJS);
    } catch (_) {}
  }

  /// メトロノームを指定BPMで開始
  static void startMetronome(int bpm) {
    try {
      globalContext.callMethod('startMetronome'.toJS, bpm.toJS);
    } catch (_) {}
  }

  /// メトロノームを停止
  static void stopMetronome() {
    try {
      globalContext.callMethod('stopMetronome'.toJS);
    } catch (_) {}
  }

  /// アップテンポBGM（ドラムビート）を開始
  static void startUpbeat() {
    try {
      globalContext.callMethod('startUpbeat'.toJS);
    } catch (_) {}
  }

  /// アップテンポBGMを停止
  static void stopUpbeat() {
    try {
      globalContext.callMethod('stopUpbeat'.toJS);
    } catch (_) {}
  }

  /// 全BGM・効果音を停止
  static void stopAll() {
    try {
      globalContext.callMethod('stopAllSounds'.toJS);
    } catch (_) {}
  }

  /// MP3ファイルをプリロード（Web Audio APIでデコード → バッファ保持）
  /// 呼び出し後、バックグラウンドでデコードされる（fire-and-forget）
  static void preloadSound(String filename) {
    try {
      globalContext.callMethod('preloadSound'.toJS, filename.toJS);
    } catch (_) {}
  }

  /// プリロード済みのサウンドバッファを即時再生
  /// レイテンシーほぼゼロ（audioplayers より高精度）
  static void playSoundBuffer(String filename) {
    try {
      globalContext.callMethod('playSoundBuffer'.toJS, filename.toJS);
    } catch (_) {}
  }

  /// 再生中のサウンドバッファを停止
  static void stopSoundBuffer() {
    try {
      globalContext.callMethod('stopSoundBuffer'.toJS);
    } catch (_) {}
  }
}
