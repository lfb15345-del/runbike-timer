import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import '../services/database_service.dart';
import '../services/web_audio_service.dart';
import '../services/web_camera_service.dart';

/// タイマーの状態
enum TimerState { waiting, countdown, measuring }

/// 計測タブ（メイン画面）
class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});

  /// 他の画面からチェック用（計測中はタブ切替をブロック）
  static bool isRunning = false;

  /// Bluetooth遅延補正（ms） - 計測・練習画面で共有
  static int bluetoothOffsetMs = 0;

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> with WidgetsBindingObserver {
  TimerState _state = TimerState.waiting;
  bool _isTeamMode = false;

  // 現在の練習対象の子ども
  int? _currentChildId;
  String _currentChildName = '未選択';
  List<Map<String, dynamic>> _children = [];

  // スタート音の設定
  final Map<String, int> _startOffsets = {
    'silent': 0,
    'basic': 10600,
    'final': 15500,
    'semi': 20050,
  };
  final Map<String, String?> _soundFiles = {
    'silent': null,
    'basic': 'sounds/start02.mp3',
    'final': 'sounds/start01.mp3',
    'semi': 'sounds/start03.mp3',
  };
  final Map<String, String> _soundLabels = {
    'silent': 'サイレント',
    'basic': '基本',
    'final': '決勝',
    'semi': '準決勝',
  };
  String _selectedSound = 'basic';

  // タイマー関連
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  DateTime? _measureStartTime;
  int _elapsedMs = 0;

  // カメラ関連
  bool _isRecordingEnabled = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isVideoRecording = false;
  String? _lastVideoPath;

  // カメラのデジタルズーム関連
  double _camMinZoom = 1.0;
  double _camMaxZoom = 1.0;
  double _camZoom = 1.0;            // 現在のズーム倍率
  double _camZoomStart = 1.0;       // ピンチ開始時のズーム倍率（差分計算用）

  // ピンチ検出用：アクティブなタッチポインタを追跡（Listener使用）
  final Map<int, Offset> _wipePointers = {};
  double _wipePinchInitDist = 0;

  // ワイプの位置とサイズ（ユーザーがドラッグ＆リサイズで変更可能）
  double? _wipeLeft;          // null = 初回起動時に画面右端に配置
  double _wipeTop = 8;
  double _wipeWidth = 140;
  double _wipeHeight = 200;

  // チームモード
  final Map<int, int> _teamFinished = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChildren();
    _initCameras();
    _preloadSounds();
  }

  /// 音声ファイルをプリロード
  Future<void> _preloadSounds() async {
    if (kIsWeb) {
      // Web版: Web Audio API でプリロード済み（unlock画面で実行）
      // 念のためここでも呼ぶ
      for (final file in _soundFiles.values) {
        if (file != null) {
          final filename = file.replaceFirst('sounds/', '');
          WebAudioService.preloadSound(filename);
        }
      }
    } else {
      // ネイティブ版: audioplayers でプリロード
      for (final file in _soundFiles.values) {
        if (file != null) {
          try {
            await _audioPlayer.setSource(AssetSource(file));
          } catch (_) {}
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioPlayer.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _isCameraInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      if (_isRecordingEnabled) {
        _setupCamera();
      }
    }
  }

  /// カメラ一覧を取得
  Future<void> _initCameras() async {
    if (kIsWeb) return; // Web版はWebCameraServiceを使う（JS経由）
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('カメラ取得エラー: $e');
    }
  }

  /// カメラをセットアップ
  Future<void> _setupCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    // 背面カメラを優先
    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      // ズーム範囲を取得（端末によって異なる、典型: 1.0〜8.0）
      try {
        _camMinZoom = await _cameraController!.getMinZoomLevel();
        _camMaxZoom = await _cameraController!.getMaxZoomLevel();
        _camZoom = _camMinZoom;
        debugPrint('カメラズーム範囲: $_camMinZoom 〜 $_camMaxZoom');
      } catch (e) {
        debugPrint('ズーム範囲取得エラー: $e');
      }
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('カメラ初期化エラー: $e');
    }
  }

  /// カメラのデジタルズームを適用（ピンチ操作から呼ぶ）
  Future<void> _applyCameraZoom(double zoom) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final clamped = zoom.clamp(_camMinZoom, _camMaxZoom);
    try {
      await _cameraController!.setZoomLevel(clamped);
      if (mounted) setState(() => _camZoom = clamped);
    } catch (e) {
      debugPrint('ズーム設定エラー: $e');
    }
  }

  /// カメラを破棄
  Future<void> _disposeCamera() async {
    if (_isVideoRecording) {
      await _stopVideoRecording();
    }
    await _cameraController?.dispose();
    _cameraController = null;
    setState(() => _isCameraInitialized = false);
  }

  /// 録画開始
  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_cameraController!.value.isRecordingVideo) return;

    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isVideoRecording = true);
    } catch (e) {
      debugPrint('録画開始エラー: $e');
    }
  }

  /// 録画停止 → 自動でギャラリーに保存
  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      setState(() => _isVideoRecording = false);
      return;
    }

    try {
      final xFile = await _cameraController!.stopVideoRecording();
      setState(() => _isVideoRecording = false);

      final savedPath = await _saveVideoToStorage(xFile.path);
      setState(() => _lastVideoPath = savedPath);
      if (savedPath == 'gallery') {
        _showMessage('動画を写真アプリに保存しました');
      } else {
        _showMessage('動画を保存しました: ${savedPath.split('/').last}');
      }
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      setState(() => _isVideoRecording = false);
      _showMessage('動画の保存に失敗しました');
    }
  }

  /// 動画ファイルを写真アプリ（ギャラリー）に保存
  Future<String> _saveVideoToStorage(String tempPath) async {
    if (kIsWeb) return tempPath;

    try {
      // ギャラリー（写真アプリ）に保存
      final success = await GallerySaver.saveVideo(
        tempPath,
        albumName: 'ランバイクタイマー',
      );

      if (success == true) {
        debugPrint('動画をギャラリーに保存しました');
        // 一時ファイルを削除
        try { await File(tempPath).delete(); } catch (_) {}
        return 'gallery'; // ギャラリー保存成功
      }
    } catch (e) {
      debugPrint('ギャラリー保存エラー: $e');
    }

    // フォールバック: アプリ固有フォルダに保存
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      final now = DateTime.now();
      final dateStr = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final ext = tempPath.split('.').last;
      final savePath = '${videoDir.path}/runbike_$dateStr.$ext';
      final tempFile = File(tempPath);
      await tempFile.copy(savePath);
      debugPrint('動画保存先（フォールバック）: $savePath');
      try { await tempFile.delete(); } catch (_) {}
      return savePath;
    } catch (e) {
      debugPrint('動画保存エラー: $e');
      return tempPath;
    }
  }

  /// 子どもリストを読み込む
  Future<void> _loadChildren() async {
    final children = await DatabaseService.getChildren();
    setState(() {
      _children = children;
      if (_currentChildId == null && children.isNotEmpty) {
        _currentChildId = children.first['id'] as int;
        _currentChildName = children.first['name'] as String;
        // 共有変数にも保存
        DatabaseService.selectedChildId = _currentChildId;
        DatabaseService.selectedChildName = _currentChildName;
      }
    });
  }

  /// タイムを見やすい文字列に変換
  String _formatTime(int ms) {
    final seconds = ms ~/ 1000;
    final millis = ms % 1000;
    return '${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  /// スタートボタン押下
  Future<void> _onStart() async {
    // スタート音のオフセット + Bluetooth補正
    final offset = _startOffsets[_selectedSound]! + MeasureScreen.bluetoothOffsetMs;
    final soundFile = _soundFiles[_selectedSound];

    setState(() {
      _state = TimerState.countdown;
      MeasureScreen.isRunning = true;
    });

    // 録画ONなら録画開始
    if (_isRecordingEnabled) {
      if (kIsWeb) {
        WebCameraService.startRecording();
        setState(() => _isVideoRecording = true);
      } else if (_isCameraInitialized) {
        await _startVideoRecording();
      }
    }

    final DateTime measureStart;

    if (soundFile != null) {
      if (kIsWeb) {
        // === Web版: Web Audio API で即時再生（レイテンシーほぼゼロ） ===
        final filename = soundFile.replaceFirst('sounds/', '');
        final playStartTime = DateTime.now();
        WebAudioService.playSoundBuffer(filename);
        measureStart = playStartTime.add(Duration(milliseconds: offset));
      } else {
        // === ネイティブ版: 従来通り即座に再生 ===
        final playStartTime = DateTime.now();
        _audioPlayer.play(AssetSource(soundFile));
        measureStart = playStartTime.add(Duration(milliseconds: offset));
      }

      final waitMs = measureStart.difference(DateTime.now()).inMilliseconds;
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }

      if (_state != TimerState.countdown) return;
    } else {
      measureStart = DateTime.now();
    }

    setState(() {
      _state = TimerState.measuring;
      _measureStartTime = measureStart;
      _elapsedMs = 0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_measureStartTime != null) {
        setState(() {
          _elapsedMs = DateTime.now().difference(_measureStartTime!).inMilliseconds;
        });
      }
    });
  }

  /// 中止ボタン
  void _onCancel() {
    if (kIsWeb) {
      WebAudioService.stopAll();
    } else {
      _audioPlayer.stop();
    }
    _timer?.cancel();

    // 録画中なら停止
    if (_isVideoRecording) {
      if (kIsWeb) {
        WebCameraService.stopRecording().then((_) {
          // 録画データがあれば確認ボタン付きで表示
          if (WebCameraService.hasPendingRecording()) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('中止しました'),
                duration: const Duration(seconds: 10),
                action: SnackBarAction(
                  label: '録画を確認',
                  textColor: Colors.yellow,
                  onPressed: () {
                    WebCameraService.showPendingRecording();
                  },
                ),
              ),
            );
          }
        });
      } else {
        _stopVideoRecording();
      }
    }

    setState(() {
      _state = TimerState.waiting;
      MeasureScreen.isRunning = false;
      _elapsedMs = 0;
      _measureStartTime = null;
      _isVideoRecording = false;
      _teamFinished.clear();
    });
  }

  /// ゴールボタン（個人モード）
  Future<void> _onGoal() async {
    final finalTime = DateTime.now().difference(_measureStartTime!).inMilliseconds;
    _timer?.cancel();

    // 録画中なら停止（プレビューはまだ出さない）
    final hadRecording = _isVideoRecording;
    if (_isVideoRecording) {
      if (kIsWeb) {
        await WebCameraService.stopRecording();
      } else {
        await _stopVideoRecording();
      }
      setState(() => _isVideoRecording = false);
    }

    setState(() {
      _elapsedMs = finalTime;
      _state = TimerState.waiting;
      MeasureScreen.isRunning = false;
      _measureStartTime = null;
    });

    if (_currentChildId == null) {
      _showMessage('先に子どもを登録してください');
      return;
    }

    final sessionId = await DatabaseService.getTodaySessionId();
    final runId = await DatabaseService.addRun(
      sessionId: sessionId,
      startSoundType: _selectedSound,
    );
    await DatabaseService.addRunResult(
      runId: runId,
      childId: _currentChildId!,
      timeMs: finalTime,
    );

    // Web版で録画ありの場合: 「録画を確認」ボタン付きメッセージ
    if (kIsWeb && hadRecording && WebCameraService.hasPendingRecording()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_formatTime(finalTime)} 秒 を記録しました！'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: '録画を確認',
            textColor: Colors.yellow,
            onPressed: () {
              WebCameraService.showPendingRecording();
            },
          ),
        ),
      );
    } else {
      _showMessage('${_formatTime(finalTime)} 秒 を記録しました！');
    }
  }

  /// チームモードでゴール
  Future<void> _onTeamGoal(int childId, String childName) async {
    if (_measureStartTime == null) return;
    if (_teamFinished.containsKey(childId)) return;

    final finalTime = DateTime.now().difference(_measureStartTime!).inMilliseconds;

    setState(() {
      _teamFinished[childId] = finalTime;
    });

    final sessionId = await DatabaseService.getTodaySessionId();
    final runId = await DatabaseService.addRun(
      sessionId: sessionId,
      startSoundType: _selectedSound,
    );
    await DatabaseService.addRunResult(
      runId: runId,
      childId: childId,
      timeMs: finalTime,
    );
  }

  /// メッセージ表示
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  /// 録画スイッチのON/OFF
  Future<void> _toggleRecording(bool value) async {
    if (kIsWeb) {
      // === Web版: JS経由でカメラ起動 ===
      setState(() => _isRecordingEnabled = value);
      if (value) {
        final ok = await WebCameraService.startPreview();
        if (!ok) {
          _showMessage('カメラを起動できませんでした');
          setState(() => _isRecordingEnabled = false);
        }
      } else {
        WebCameraService.stopPreview();
      }
      return;
    }

    // === ネイティブ版: camera パッケージ ===
    setState(() => _isRecordingEnabled = value);

    if (value) {
      await _setupCamera();
    } else {
      await _disposeCamera();
    }
  }

  /// 子ども選択ダイアログ
  Future<void> _showChildSelector() async {
    await _loadChildren();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('子どもを選ぶ'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._children.map((child) {
                final childId = child['id'] as int;
                final childName = child['name'] as String;
                return ListTile(
                  title: Text(childName),
                  selected: childId == _currentChildId,
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (action) async {
                      if (action == 'edit') {
                        Navigator.pop(context);
                        await _showEditChildDialog(childId, childName);
                      } else if (action == 'delete') {
                        Navigator.pop(context);
                        await _showDeleteChildDialog(childId, childName);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('名前を変更')),
                      const PopupMenuItem(value: 'delete', child: Text('削除', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _currentChildId = childId;
                      _currentChildName = childName;
                    });
                    DatabaseService.selectedChildId = childId;
                    DatabaseService.selectedChildName = childName;
                    Navigator.pop(context);
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('新しい子どもを追加'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddChildDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 子どもの名前変更ダイアログ
  Future<void> _showEditChildDialog(int childId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前を変更'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('変更'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await DatabaseService.updateChildName(childId, result.trim());
      await _loadChildren();
      if (_currentChildId == childId) {
        setState(() => _currentChildName = result.trim());
      }
    }
  }

  /// 子どもの削除確認ダイアログ
  Future<void> _showDeleteChildDialog(int childId, String childName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('$childName を削除しますか？\n記録データも見られなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteChild(childId);
      await _loadChildren();
      if (_currentChildId == childId) {
        setState(() {
          _currentChildId = _children.isNotEmpty ? _children.first['id'] as int : null;
          _currentChildName = _children.isNotEmpty ? _children.first['name'] as String : '未選択';
        });
      }
    }
  }

  /// 子ども追加ダイアログ
  Future<void> _showAddChildDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('子どもの名前を入力'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例: ゆうた'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final id = await DatabaseService.addChild(result.trim());
      await _loadChildren();
      setState(() {
        _currentChildId = id;
        _currentChildName = result.trim();
      });
      DatabaseService.selectedChildId = id;
      DatabaseService.selectedChildName = result.trim();
    }
  }

  /// カメラプレビューウィジェット（ワイプ表示）
  /// - 指2本でピンチ → カメラのデジタルズーム
  /// - 1本指でドラッグ → ワイプを画面内で移動
  /// - 右下のリサイズハンドル(↘) → ワイプサイズ変更
  /// - 右上の📷ボタン → 前面/背面カメラ切替
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    // 初回は画面右上に配置
    _wipeLeft ??= screenSize.width - _wipeWidth - 8;
    // 画面外にはみ出さないようクランプ
    final maxLeft = (screenSize.width - _wipeWidth).clamp(0.0, double.infinity);
    final maxTop = (screenSize.height - _wipeHeight - 80).clamp(0.0, double.infinity);
    final left = _wipeLeft!.clamp(0.0, maxLeft);
    final top = _wipeTop.clamp(0.0, maxTop);

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: _wipeWidth,
        height: _wipeHeight,
        // Listener: 生のポインターイベントでピンチ検出（ジェスチャー競合の影響なし）
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _wipePointers[e.pointer] = e.position;
            if (_wipePointers.length == 2) {
              final pts = _wipePointers.values.toList();
              _wipePinchInitDist = (pts[0] - pts[1]).distance;
              _camZoomStart = _camZoom;
            }
          },
          onPointerMove: (e) {
            if (!_wipePointers.containsKey(e.pointer)) return;
            _wipePointers[e.pointer] = e.position;
            if (_wipePointers.length >= 2 && _wipePinchInitDist > 5) {
              final pts = _wipePointers.values.toList();
              final dist = (pts[0] - pts[1]).distance;
              _applyCameraZoom(_camZoomStart * dist / _wipePinchInitDist);
            }
          },
          onPointerUp: (e) {
            _wipePointers.remove(e.pointer);
            if (_wipePointers.length < 2) _wipePinchInitDist = 0;
          },
          onPointerCancel: (e) {
            _wipePointers.remove(e.pointer);
            if (_wipePointers.length < 2) _wipePinchInitDist = 0;
          },
          // 1本指ドラッグでワイプ移動
          child: GestureDetector(
            onPanUpdate: (details) {
              if (_wipePointers.length >= 2) return; // ピンチ中は移動しない
              setState(() {
                _wipeLeft = (left + details.delta.dx)
                    .clamp(0.0, screenSize.width - _wipeWidth);
                _wipeTop = (top + details.delta.dy)
                    .clamp(0.0, screenSize.height - _wipeHeight - 80);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isVideoRecording ? Colors.red : Colors.white,
                  width: _isVideoRecording ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // カメラ映像
                    CameraPreview(_cameraController!),

                    // ── ズーム倍率インジケータ（左上） ──
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_camZoom.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // ── 右上: 📷 カメラ切替ボタン ──
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _switchCamera,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flip_camera_android,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),

                    // ── 移動ヒント（左下、目立たない） ──
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.open_with,
                            color: Colors.white70, size: 12),
                      ),
                    ),

                    // ── 右下: リサイズハンドル ──
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          setState(() {
                            _wipeWidth = (_wipeWidth + details.delta.dx)
                                .clamp(80.0, screenSize.width - 16);
                            _wipeHeight = (_wipeHeight + details.delta.dy)
                                .clamp(100.0, screenSize.height - 100);
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                            ),
                          ),
                          child: const Icon(
                            Icons.south_east,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 前面/背面カメラ切替
  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    final currentDirection = _cameraController!.description.lensDirection;
    final newCamera = _cameras!.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => _cameras!.first,
    );
    _cameraController?.dispose();
    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: true,
    );
    _cameraController!.initialize().then((_) async {
      try {
        _camMinZoom = await _cameraController!.getMinZoomLevel();
        _camMaxZoom = await _cameraController!.getMaxZoomLevel();
        _camZoom = _camMinZoom;
      } catch (_) {}
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
    final isMeasuring = _state == TimerState.measuring;

    return Scaffold(
      // 計測中は背景色を変えて視覚的に強調
      backgroundColor: isMeasuring ? Colors.green[50] : null,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- 上部: 日付・子ども・モード（計測中は最小限） ---
                  if (!isMeasuring) ...[
                    Text(dateStr, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentChildName,
                        style: TextStyle(
                          fontSize: isMeasuring ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: isMeasuring ? Colors.green[800] : null,
                        ),
                      ),
                      if (!isMeasuring) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _state == TimerState.waiting ? _showChildSelector : null,
                          child: const Text('変更'),
                        ),
                      ],
                    ],
                  ),
                  if (!isMeasuring) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('個人'),
                        Switch(
                          value: _isTeamMode,
                          onChanged: _state == TimerState.waiting
                              ? (v) => setState(() => _isTeamMode = v)
                              : null,
                        ),
                        const Text('チーム'),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // --- 中央: タイマー表示（計測中はさらに大きく） ---
                  Text(
                    _formatTime(_elapsedMs),
                    style: TextStyle(
                      fontSize: isMeasuring ? 88 : 72,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isMeasuring ? Colors.green[900] : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _state == TimerState.waiting
                        ? '待機中'
                        : _state == TimerState.countdown
                            ? 'カウントダウン中...'
                            : '計測中',
                    style: TextStyle(
                      fontSize: 18,
                      color: _state == TimerState.measuring ? Colors.red : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- スタート音選択（計測中は非表示） ---
                  if (!isMeasuring)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _soundLabels.entries.map((entry) {
                        final isSelected = _selectedSound == entry.key;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: isSelected,
                            onSelected: _state == TimerState.waiting
                                ? (_) => setState(() => _selectedSound = entry.key)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                  if (!isMeasuring) const SizedBox(height: 8),

                  // --- 録画スイッチ（計測中は非表示） ---
                  if (!isMeasuring)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isVideoRecording ? Icons.fiber_manual_record : Icons.videocam,
                          size: 20,
                          color: _isVideoRecording ? Colors.red : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isVideoRecording ? '録画中' : '録画',
                          style: TextStyle(
                            color: _isVideoRecording ? Colors.red : null,
                            fontWeight: _isVideoRecording ? FontWeight.bold : null,
                          ),
                        ),
                        Switch(
                          value: _isRecordingEnabled,
                          onChanged: _state == TimerState.waiting ? _toggleRecording : null,
                          activeColor: Colors.red,
                        ),
                      ],
                    ),

                  // --- Bluetooth遅延補正（計測中は非表示） ---
                  if (!isMeasuring)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth,
                            size: 18,
                            color: MeasureScreen.bluetoothOffsetMs > 0 ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BT補正',
                            style: TextStyle(
                              fontSize: 13,
                              color: MeasureScreen.bluetoothOffsetMs > 0 ? Colors.blue : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // マイナスボタン
                          SizedBox(
                            width: 32, height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              onPressed: _state == TimerState.waiting && MeasureScreen.bluetoothOffsetMs > 0
                                  ? () => setState(() => MeasureScreen.bluetoothOffsetMs = (MeasureScreen.bluetoothOffsetMs - 50).clamp(0, 500))
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ),
                          // 現在値
                          Container(
                            width: 72,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MeasureScreen.bluetoothOffsetMs > 0
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${MeasureScreen.bluetoothOffsetMs}ms',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: MeasureScreen.bluetoothOffsetMs > 0 ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ),
                          // プラスボタン
                          SizedBox(
                            width: 32, height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              onPressed: _state == TimerState.waiting && MeasureScreen.bluetoothOffsetMs < 500
                                  ? () => setState(() => MeasureScreen.bluetoothOffsetMs = (MeasureScreen.bluetoothOffsetMs + 50).clamp(0, 500))
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // --- メイン操作ボタン ---
                  if (_state == TimerState.waiting)
                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: _onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('スタート（3,2,1,GO!）',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  if (_state == TimerState.countdown)
                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: _onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('中止',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  if (_state == TimerState.measuring && !_isTeamMode)
                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: _onGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('ゴール！',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  // --- チームモード: 子どもボタン ---
                  if (_isTeamMode && _state == TimerState.measuring) ...[
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        children: _children.map((child) {
                          final childId = child['id'] as int;
                          final childName = child['name'] as String;
                          final isFinished = _teamFinished.containsKey(childId);
                          final finishTime = _teamFinished[childId];
                          int rank = 0;
                          if (isFinished) {
                            rank = _teamFinished.values
                                .where((t) => t <= finishTime!)
                                .length;
                          }

                          return ElevatedButton(
                            onPressed: isFinished
                                ? null
                                : () => _onTeamGoal(childId, childName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFinished ? Colors.grey[400] : Colors.blue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.green[100],
                              disabledForegroundColor: Colors.green[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  childName,
                                  style: TextStyle(
                                    fontSize: isFinished ? 16 : 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isFinished)
                                  Text(
                                    '${rank}着 ${_formatTime(finishTime!)}秒',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('次のレースへ', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // --- カメラプレビュー（ワイプ）ネイティブ版のみ ---
            // Web版はJS側でHTMLビデオ要素をフローティング表示
            if (!kIsWeb && _isRecordingEnabled && _isCameraInitialized)
              _buildCameraPreview(),
          ],
        ),
      ),
    );
  }
}

