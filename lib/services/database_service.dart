/// プラットフォームに応じてDB実装を切り替え
/// - Android/iOS → sqflite（永続保存）
/// - Web → インメモリ＋localStorage（ブラウザに保存）
export 'database_service_native.dart'
    if (dart.library.html) 'database_service_web.dart';
