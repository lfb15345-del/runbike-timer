import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'video_saver.dart';

/// 練習タブ用の録画係（ネイティブ版のみ）
/// - 走る区間ごとに start() → stop() で1本ずつ録画し、写真アプリに保存する
/// - start/stop/保存は順番待ちで1つずつ実行する
///   （前の動画の保存が終わる前に次の録画が始まって壊れるのを防ぐ）
class PracticeRecorder extends ChangeNotifier {
  List<CameraDescription>? _cameras;
  CameraController? controller;

  double minZoom = 1.0;
  double maxZoom = 1.0;
  double zoom = 1.0;

  /// この練習で写真アプリに保存できた本数
  int savedCount = 0;

  /// 写真へのアクセスが無くて保存できなかったか
  bool accessDenied = false;

  Future<void> _queue = Future.value();

  bool get isReady => controller?.value.isInitialized ?? false;
  bool get isRecording => controller?.value.isRecordingVideo ?? false;

  /// 順番待ちに処理を追加（失敗しても後ろの処理は止めない）
  Future<void> _enqueue(Future<void> Function() job) {
    _queue = _queue.then((_) => job()).catchError((Object e) {
      debugPrint('練習録画エラー: $e');
    });
    return _queue;
  }

  /// カメラを起動（背面カメラ優先）
  Future<void> open() => _enqueue(() async {
        if (isReady) return;
        _cameras ??= await availableCameras();
        if (_cameras!.isEmpty) return;
        final camera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        await _initController(camera);
      });

  Future<void> _initController(CameraDescription camera) async {
    final c = CameraController(camera, ResolutionPreset.medium,
        enableAudio: true);
    controller = c;
    await c.initialize();
    try {
      minZoom = await c.getMinZoomLevel();
      maxZoom = await c.getMaxZoomLevel();
      zoom = minZoom;
    } catch (_) {}
    notifyListeners();
  }

  /// カメラを閉じる（録画中なら止めて保存してから）
  Future<void> close() => _enqueue(() async {
        await _stopAndSave();
        final c = controller;
        controller = null;
        notifyListeners();
        await c?.dispose();
      });

  /// 前面/背面カメラ切替（録画中は切り替えない）
  Future<void> switchCamera() => _enqueue(() async {
        if (_cameras == null || _cameras!.length < 2 || !isReady) return;
        if (isRecording) return;
        final current = controller!.description.lensDirection;
        final next = _cameras!.firstWhere(
          (c) => c.lensDirection != current,
          orElse: () => _cameras!.first,
        );
        final old = controller;
        controller = null;
        notifyListeners();
        await old?.dispose();
        await _initController(next);
      });

  /// デジタルズーム（ワイプのピンチ操作から）
  Future<void> setZoom(double value) async {
    if (!isReady) return;
    final clamped = value.clamp(minZoom, maxZoom);
    try {
      await controller!.setZoomLevel(clamped);
      zoom = clamped;
      notifyListeners();
    } catch (_) {}
  }

  /// 練習の最初に呼ぶ（保存本数のカウントをリセット）
  void resetCount() {
    savedCount = 0;
    accessDenied = false;
    notifyListeners();
  }

  /// 走る区間の録画を開始
  Future<void> start() => _enqueue(() async {
        if (!isReady || isRecording) return;
        await controller!.startVideoRecording();
        notifyListeners();
      });

  /// 走る区間の録画を止めて写真アプリに保存
  Future<void> stop() => _enqueue(_stopAndSave);

  Future<void> _stopAndSave() async {
    if (!isReady || !isRecording) return;
    final file = await controller!.stopVideoRecording();
    notifyListeners();
    final result = await VideoSaver.save(file.path);
    if (result == VideoSaveResult.gallery) {
      savedCount++;
    } else if (result == VideoSaveResult.denied) {
      accessDenied = true;
    }
    notifyListeners();
  }

  /// 順番待ちの処理（保存など）がすべて終わるまで待つ
  Future<void> waitIdle() => _queue;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
