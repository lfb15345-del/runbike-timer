import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
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
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('カメラ初期化エラー: $e');
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

  /// 録画停止・保存
  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      setState(() => _isVideoRecording = false);
      return;
    }

    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() {
        _isVideoRecording = false;
        _lastVideoPath = file.path;
      });
      _showMessage('動画を保存しました');
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      setState(() => _isVideoRecording = false);
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
        // Web版: 録画停止 → 自動ダウンロード
        WebCameraService.stopRecording().then((_) {
          _showMessage('録画をダウンロードしました');
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

    // 録画中なら停止
    if (_isVideoRecording) {
      if (kIsWeb) {
        await WebCameraService.stopRecording();
        _showMessage('録画をダウンロードしました');
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

    _showMessage('${_formatTime(finalTime)} 秒 を記録しました！');
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
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: () {
          // タップで前面/背面カメラ切替
          if (_cameras != null && _cameras!.length > 1) {
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
            _cameraController!.initialize().then((_) {
              if (mounted) setState(() {});
            });
          }
        },
        child: Container(
          width: 120,
          height: 160,
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
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
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
