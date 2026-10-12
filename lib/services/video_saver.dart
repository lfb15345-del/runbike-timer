import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// 録画した動画の保存先（写真アプリ / 許可なしで失敗 / アプリ内に退避）
enum VideoSaveResult { gallery, denied, appFolder }

/// 録画した動画を写真アプリに保存する窓口（計測タブ・練習タブで共通）
class VideoSaver {
  static const String _album = 'ランバイクタイマー';

  /// 写真アプリへのアクセスが無いときの案内文
  static const String deniedMessage =
      '写真へのアクセスが許可されていないため、写真アプリに保存できませんでした。\n'
      '設定 → ランバイクタイマー → 写真 を「フルアクセス」にしてください';

  /// 動画ファイルを写真アプリ（ギャラリー）に保存
  /// 1. アルバム付きで保存（写真への「フルアクセス」が必要）
  /// 2. ダメならアルバムなしで保存（「追加のみ」の許可でも通る）
  /// 3. それでもダメならアプリ内フォルダに退避
  static Future<VideoSaveResult> save(String tempPath) async {
    if (kIsWeb) return VideoSaveResult.appFolder;

    var accessDenied = false;
    try {
      // 許可がなければこの場で求める（初回はiOSのダイアログが出る）
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putVideo(tempPath, album: _album);
      await _deleteQuietly(tempPath);
      return VideoSaveResult.gallery;
    } on GalException catch (e) {
      debugPrint('ギャラリー保存エラー（アルバム付き）: ${e.type}');
      accessDenied = e.type == GalExceptionType.accessDenied;
    } catch (e) {
      debugPrint('ギャラリー保存エラー（アルバム付き）: $e');
    }

    // アルバム作成には「フルアクセス」が要るので、「追加のみ」許可の場合はここで通る
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      await Gal.putVideo(tempPath);
      await _deleteQuietly(tempPath);
      return VideoSaveResult.gallery;
    } on GalException catch (e) {
      debugPrint('ギャラリー保存エラー（アルバムなし）: ${e.type}');
      accessDenied = accessDenied || e.type == GalExceptionType.accessDenied;
    } catch (e) {
      debugPrint('ギャラリー保存エラー（アルバムなし）: $e');
    }

    // フォールバック: アプリ固有フォルダに保存
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final dateStr = '${now.year}${two(now.month)}${two(now.day)}_'
          '${two(now.hour)}${two(now.minute)}${two(now.second)}';
      final ext = tempPath.split('.').last;
      await File(tempPath).copy('${videoDir.path}/runbike_$dateStr.$ext');
      await _deleteQuietly(tempPath);
    } catch (e) {
      debugPrint('動画保存エラー: $e');
    }
    return accessDenied ? VideoSaveResult.denied : VideoSaveResult.appFolder;
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
