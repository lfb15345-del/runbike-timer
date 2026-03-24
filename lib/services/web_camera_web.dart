import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web版専用: JavaScript の getUserMedia + MediaRecorder を呼び出す
/// index.html に定義したカメラ関数を Dart から呼ぶ
class WebCameraService {
  /// カメラが利用可能か確認
  static bool isAvailable() {
    try {
      final result = globalContext.callMethod('isCameraAvailable'.toJS);
      return result?.dartify() == true;
    } catch (_) {
      return false;
    }
  }

  /// カメラプレビュー開始（画面右上にPiP表示）
  static Future<bool> startPreview() async {
    try {
      final result = globalContext.callMethod('startCameraPreview'.toJS);
      if (result != null) {
        final dartResult = await (result as JSPromise<JSAny?>).toDart;
        return dartResult?.dartify() == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// カメラプレビュー停止
  static void stopPreview() {
    try {
      globalContext.callMethod('stopCameraPreview'.toJS);
    } catch (_) {}
  }

  /// 録画開始
  static bool startRecording() {
    try {
      final result = globalContext.callMethod('startCameraRecording'.toJS);
      return result?.dartify() == true;
    } catch (_) {
      return false;
    }
  }

  /// 録画停止（自動ダウンロード）
  static Future<bool> stopRecording() async {
    try {
      final result = globalContext.callMethod('stopCameraRecording'.toJS);
      if (result != null) {
        final dartResult = await (result as JSPromise<JSAny?>).toDart;
        return dartResult?.dartify() == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 録画中かどうか
  static bool isRecording() {
    try {
      final result = globalContext.callMethod('isCameraRecording'.toJS);
      return result?.dartify() == true;
    } catch (_) {
      return false;
    }
  }

  /// カメラプレビューの表示/非表示（タブ切替時）
  static void setPreviewVisible(bool visible) {
    try {
      globalContext.callMethod('setCameraPreviewVisible'.toJS, visible.toJS);
    } catch (_) {}
  }

  /// 保留中の録画プレビューを表示
  static bool showPendingRecording() {
    try {
      final result = globalContext.callMethod('showPendingRecording'.toJS);
      return result?.dartify() == true;
    } catch (_) {
      return false;
    }
  }

  /// 保留中の録画があるか確認
  static bool hasPendingRecording() {
    try {
      final result = globalContext.callMethod('hasPendingRecording'.toJS);
      return result?.dartify() == true;
    } catch (_) {
      return false;
    }
  }
}
