/// ネイティブ版のスタブ（何もしない）
/// Web版では web_camera_web.dart が使われる
class WebCameraService {
  static bool isAvailable() => false;
  static Future<bool> startPreview() async => false;
  static void stopPreview() {}
  static bool startRecording() => false;
  static Future<bool> stopRecording() async => false;
  static bool isRecording() => false;
  static void setPreviewVisible(bool visible) {}
  static bool showPendingRecording() => false;
  static bool hasPendingRecording() => false;
}
