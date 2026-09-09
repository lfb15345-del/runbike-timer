import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../constants/sound_config.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';
import '../services/app_settings.dart';
import '../services/web_camera_service.dart';
import '../widgets/bt_offset_control.dart';
import '../widgets/camera_wipe.dart';
import '../widgets/timer_text.dart';
import '../theme.dart';

/// タイマーの状態
enum TimerState { waiting, countdown, measuring }

/// 録画した動画の保存先（写真アプリ / 許可なしで失敗 / アプリ内に退避）
enum _VideoSaveResult { gallery, denied, appFolder }

/// 計測タブ（メイン画面）
class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});

  /// 他の画面からチェック用（計測中はタブ切替をブロック）
  static bool isRunning = false;

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen>
    with WidgetsBindingObserver {
  TimerState _state = TimerState.waiting;
  bool _isTeamMode = false;

  // 現在の練習対象の子ども
  int? _currentChildId;
  String _currentChildName = '未選択';
  List<Map<String, dynamic>> _children = [];

  // 選択中のスタート音（定義は SoundConfig に一元化）
  StartSound _selectedSound = SoundConfig.basic;

  // 選択中の計測中BGM（走行の疾走感演出。デフォルトはなし）
  MeasureBgm _selectedBgm = MeasureBgmConfig.none;

  // タイマー関連
  Timer? _timer;
  DateTime? _measureStartTime;
  int _elapsedMs = 0;

  // スタートの世代番号（連打や「中止→即再スタート」で古い処理が生き残るのを防ぐ）
  int _startGeneration = 0;

  // カメラ関連
  bool _isRecordingEnabled = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isVideoRecording = false;

  // カメラのデジタルズーム関連
  double _camMinZoom = 1.0;
  double _camMaxZoom = 1.0;
  double _camZoom = 1.0;

  // チームモード
  final Map<int, int> _teamFinished = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChildren();
    _initCameras();
    SoundService.preloadStartSounds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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

  // ========================================
  //  カメラ制御（ネイティブ版）
  // ========================================

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

  /// カメラのデジタルズームを適用（ワイプのピンチ操作から呼ばれる）
  Future<void> _applyCameraZoom(double zoom) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final clamped = zoom.clamp(_camMinZoom, _camMaxZoom);
    try {
      await _cameraController!.setZoomLevel(clamped);
      if (mounted) setState(() => _camZoom = clamped);
    } catch (e) {
      debugPrint('ズーム設定エラー: $e');
    }
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
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      setState(() => _isVideoRecording = false);
      return;
    }

    try {
      final xFile = await _cameraController!.stopVideoRecording();
      setState(() => _isVideoRecording = false);

      final result = await _saveVideoToStorage(xFile.path);
      switch (result) {
        case _VideoSaveResult.gallery:
          _showMessage('動画を写真アプリに保存しました（アルバム「ランバイクタイマー」）');
        case _VideoSaveResult.denied:
          _showMessage(
            '写真へのアクセスが許可されていないため、写真アプリに保存できませんでした。\n'
            '設定 → ランバイクタイマー → 写真 を「フルアクセス」にしてください',
            seconds: 8,
          );
        case _VideoSaveResult.appFolder:
          _showMessage('写真アプリに保存できなかったため、アプリ内に退避しました', seconds: 5);
      }
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      setState(() => _isVideoRecording = false);
      _showMessage('動画の保存に失敗しました');
    }
  }

  /// 動画ファイルを写真アプリ（ギャラリー）に保存
  /// 1. アルバム付きで保存（写真への「フルアクセス」が必要）
  /// 2. ダメならアルバムなしで保存（「追加のみ」の許可でも通る）
  /// 3. それでもダメならアプリ内フォルダに退避
  Future<_VideoSaveResult> _saveVideoToStorage(String tempPath) async {
    if (kIsWeb) return _VideoSaveResult.appFolder;

    var accessDenied = false;
    try {
      // 許可がなければこの場で求める（初回はiOSのダイアログが出る）
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putVideo(tempPath, album: 'ランバイクタイマー');
      try {
        await File(tempPath).delete();
      } catch (_) {}
      return _VideoSaveResult.gallery;
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
      try {
        await File(tempPath).delete();
      } catch (_) {}
      return _VideoSaveResult.gallery;
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
      try {
        await tempFile.delete();
      } catch (_) {}
    } catch (e) {
      debugPrint('動画保存エラー: $e');
    }
    return accessDenied ? _VideoSaveResult.denied : _VideoSaveResult.appFolder;
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

  // ========================================
  //  計測制御
  // ========================================

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
    // 表示は2桁（1/100秒）まで。記録自体はミリ秒精度で保存している
    final seconds = ms ~/ 1000;
    final centis = (ms % 1000) ~/ 10;
    return '${seconds.toString().padLeft(2, '0')}.${centis.toString().padLeft(2, '0')}';
  }

  /// スタートボタン押下
  Future<void> _onStart() async {
    // 連打防止: 待機中でなければ受け付けない（画面が切り替わる前の2度押し対策）
    if (_state != TimerState.waiting) return;
    final generation = ++_startGeneration;

    // スタート音のオフセット + Bluetooth補正
    final offset = _selectedSound.offsetMs + AppSettings.bluetoothOffsetMs;

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

    if (_selectedSound.assetPath != null) {
      final playStartTime = DateTime.now();
      SoundService.playStartSound(_selectedSound);
      measureStart = playStartTime.add(Duration(milliseconds: offset));

      final waitMs = measureStart.difference(DateTime.now()).inMilliseconds;
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }

      // 待っている間に中止・再スタートされていたら、この古い処理は破棄する
      if (generation != _startGeneration || _state != TimerState.countdown) {
        return;
      }
    } else {
      measureStart = DateTime.now();
    }

    setState(() {
      _state = TimerState.measuring;
      _measureStartTime = measureStart;
      _elapsedMs = 0;
    });

    // 計測中BGM: 選択されていればGO!と同時にループ再生
    if (_selectedBgm.filename != null) {
      SoundService.startMeasureBgm(_selectedBgm.filename!);
    }

    _timer?.cancel(); // 古いタイマーが残っていたら止める（表示ずれ防止）
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_measureStartTime != null) {
        setState(() {
          _elapsedMs =
              DateTime.now().difference(_measureStartTime!).inMilliseconds;
        });
      }
    });
  }

  /// 中止ボタン
  void _onCancel() {
    SoundService.stopAll();
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
    final finalTime =
        DateTime.now().difference(_measureStartTime!).inMilliseconds;
    _timer?.cancel();
    SoundService.stopBgm(); // 計測中BGMを停止

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
      startSoundType: _selectedSound.key,
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

    final finalTime =
        DateTime.now().difference(_measureStartTime!).inMilliseconds;

    setState(() {
      _teamFinished[childId] = finalTime;
    });

    final sessionId = await DatabaseService.getTodaySessionId();
    final runId = await DatabaseService.addRun(
      sessionId: sessionId,
      startSoundType: _selectedSound.key,
    );
    await DatabaseService.addRunResult(
      runId: runId,
      childId: childId,
      timeMs: finalTime,
    );
  }

  /// メッセージ表示
  void _showMessage(String msg, {int seconds = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: Duration(seconds: seconds)),
    );
  }

  // ========================================
  //  子ども管理ダイアログ
  // ========================================

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
                      const PopupMenuItem(
                          value: 'delete',
                          child:
                              Text('削除', style: TextStyle(color: Colors.red))),
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
          _currentChildId =
              _children.isNotEmpty ? _children.first['id'] as int : null;
          _currentChildName =
              _children.isNotEmpty ? _children.first['name'] as String : '未選択';
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

  // ========================================
  //  UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr =
        '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
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
                    Text(dateStr,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey)),
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
                          onPressed: _state == TimerState.waiting
                              ? _showChildSelector
                              : null,
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
                  // TimerText = 1文字ずつ固定幅で描いて震えを防止
                  // FittedBox = 1行のまま画面幅に収める（改行・はみ出し防止）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TimerText(
                        _formatTime(_elapsedMs),
                        style: AppTheme.timerStyle(
                          fontSize: isMeasuring ? 88 : 72,
                          color: isMeasuring ? Colors.green[900] : null,
                        ),
                      ),
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
                      color: _state == TimerState.measuring
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- スタート音選択（計測中は非表示） ---
                  if (!isMeasuring)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: SoundConfig.all.map((sound) {
                        final isSelected = _selectedSound.key == sound.key;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(sound.label),
                            selected: isSelected,
                            onSelected: _state == TimerState.waiting
                                ? (_) =>
                                    setState(() => _selectedSound = sound)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                  // --- 計測中BGM選択（走行の疾走感演出。計測中は非表示） ---
                  // Wrapで狭い画面でも見切れず折り返す
                  if (!isMeasuring) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        const Icon(Icons.music_note, size: 16,
                            color: Colors.grey),
                        const Text('走行中BGM:',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey)),
                        ...MeasureBgmConfig.all.map((bgm) {
                          final isSelected = _selectedBgm.key == bgm.key;
                          return ChoiceChip(
                            label: Text(bgm.label,
                                style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            selected: isSelected,
                            onSelected: _state == TimerState.waiting
                                ? (_) => setState(() => _selectedBgm = bgm)
                                : null,
                          );
                        }),
                      ],
                    ),
                  ],

                  if (!isMeasuring) const SizedBox(height: 8),

                  // --- 録画スイッチ（計測中は非表示） ---
                  if (!isMeasuring)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isVideoRecording
                              ? Icons.fiber_manual_record
                              : Icons.videocam,
                          size: 20,
                          color: _isVideoRecording ? Colors.red : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isVideoRecording ? '録画中' : '録画',
                          style: TextStyle(
                            color: _isVideoRecording ? Colors.red : null,
                            fontWeight:
                                _isVideoRecording ? FontWeight.bold : null,
                          ),
                        ),
                        Switch(
                          value: _isRecordingEnabled,
                          onChanged: _state == TimerState.waiting
                              ? _toggleRecording
                              : null,
                          activeThumbColor: Colors.red,
                        ),
                      ],
                    ),

                  // --- Bluetooth遅延補正（計測中は非表示） ---
                  if (!isMeasuring)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: BtOffsetControl(
                        enabled: _state == TimerState.waiting,
                        onChanged: () => setState(() {}),
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
                          backgroundColor: AppTheme.brandGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('スタート（3,2,1,GO!）',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
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
                        ),
                        child: const Text('中止',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  if (_state == TimerState.measuring && !_isTeamMode)
                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: _onGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goRed,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ゴール！',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
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
                          final isFinished =
                              _teamFinished.containsKey(childId);
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
                              backgroundColor:
                                  isFinished ? Colors.grey[400] : Colors.blue,
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
                                    '$rank着 ${_formatTime(finishTime!)}秒',
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
                          backgroundColor: AppTheme.accentAmber,
                          foregroundColor: const Color(0xFF072016),
                        ),
                        child: const Text('次のレースへ',
                            style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // --- カメラプレビュー（ワイプ）ネイティブ版のみ ---
            // Web版はJS側でHTMLビデオ要素をフローティング表示
            if (!kIsWeb &&
                _isRecordingEnabled &&
                _isCameraInitialized &&
                _cameraController != null)
              CameraWipe(
                controller: _cameraController!,
                isRecording: _isVideoRecording,
                zoom: _camZoom,
                onZoomRequest: _applyCameraZoom,
                onSwitchCamera: _switchCamera,
              ),
          ],
        ),
      ),
    );
  }
}
