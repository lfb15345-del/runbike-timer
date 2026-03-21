/// プラットフォームに応じてWeb Audio実装を切り替え
/// - Web → JavaScript Web Audio API で音を生成
/// - Android/iOS → スタブ（何もしない、audioplayers を使う）
export 'web_audio_stub.dart'
    if (dart.library.html) 'web_audio_web.dart';
