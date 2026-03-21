/// プラットフォームに応じてWeb Camera実装を切り替え
/// - Web → JavaScript getUserMedia + MediaRecorder
/// - Android/iOS → スタブ（何もしない、camera パッケージを使う）
export 'web_camera_stub.dart'
    if (dart.library.html) 'web_camera_web.dart';
