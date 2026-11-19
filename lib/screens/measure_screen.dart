import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import '../constants/sound_config.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';
import '../services/app_settings.dart';
import '../services/background_keeper.dart';
import '../services/review_prompter.dart';
import '../services/web_camera_service.dart';
import '../services/video_saver.dart';
import '../widgets/bt_offset_control.dart';
import '../widgets/camera_wipe.dart';
import '../widgets/select_pill.dart';
import '../widgets/timer_text.dart';
import '../theme.dart';
import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import 'practice_screen.dart';

/// タイマーの状態
enum TimerState { waiting, countdown, measuring }

/// 計測タブ（メイン画面）
class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});

  /// 他の画面からチェック用（計測中かどうか）
  static bool isRunning = false;

  /// 録画スイッチがONか（録画しながらの計測中はタブ切替を止めるため）
  static bool isRecordingOn = false;

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  TimerState _state = TimerState.waiting;
  bool _isTeamMode = false;

  // 現在の練習対象の子ども
  int? _currentChildId;
  String _currentChildName = ''; // 空 = まだ選ばれていない
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

  // カウントダウン（READY）の進み具合バー
  late final AnimationController _readyController;
  DateTime? _countdownStartTime; // カウントダウンを始めた時刻
  int _countdownTotalMs = 0; // GO!までの長さ

  /// 画面の文字（端末の言語に合わせた翻訳）
  AppLocalizations get l => AppLocalizations.of(context);

  /// 表示用の子どもの名前（未選択なら「未選択」）
  String get _childLabel =>
      _currentChildName.isEmpty ? l.notSelected : _currentChildName;

  @override
  void initState() {
    super.initState();
    _readyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    WidgetsBinding.instance.addObserver(this);
    _loadChildren();
    _initCameras();
    SoundService.preloadStartSounds();
    AppSettings.currentTab.addListener(_onTabChanged);
  }

  /// 他のタブ（練習など）に移ったらカメラを手放し、戻ってきたら付け直す
  /// （カメラは同時に1画面しか使えないため。録画スイッチ自体はONのまま）
  void _onTabChanged() {
    // 別のタブから戻ってきたとき、READYのバーを実際の経過時間に合わせ直す
    // （隠れている間はバーのアニメーションが止まるため）
    if (AppSettings.currentTab.value == 0 &&
        _state == TimerState.countdown &&
        _countdownStartTime != null &&
        _countdownTotalMs > 0) {
      final elapsedMs =
          DateTime.now().difference(_countdownStartTime!).inMilliseconds;
      _readyController.forward(
          from: (elapsedMs / _countdownTotalMs).clamp(0.0, 1.0).toDouble());
    }
    if (kIsWeb || !_isRecordingEnabled) return;
    if (AppSettings.currentTab.value == 0) {
      if (!_isCameraInitialized) _setupCamera();
    } else if (_cameraController != null) {
      _disposeCamera();
    }
  }

  @override
  void dispose() {
    AppSettings.currentTab.removeListener(_onTabChanged);
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _readyController.dispose();
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
      // 計測タブを表示中のときだけカメラを付け直す（練習タブがカメラを使っている場合があるため）
      if (_isRecordingEnabled && AppSettings.currentTab.value == 0) {
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

      final result = await VideoSaver.save(xFile.path);
      switch (result) {
        case VideoSaveResult.gallery:
          _showMessage(l.videoSavedToPhotos(AppLanguage.albumName));
        case VideoSaveResult.denied:
          _showMessage(l.photoAccessDenied(l.appTitle), seconds: 8);
        case VideoSaveResult.appFolder:
          _showMessage(l.videoSavedInApp, seconds: 5);
      }
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      setState(() => _isVideoRecording = false);
      _showMessage(l.videoSaveFailed);
    }
  }

  /// 録画スイッチのON/OFF
  Future<void> _toggleRecording(bool value) async {
    MeasureScreen.isRecordingOn = value;
    if (kIsWeb) {
      // === Web版: JS経由でカメラ起動 ===
      setState(() => _isRecordingEnabled = value);
      if (value) {
        final ok = await WebCameraService.startPreview();
        if (!ok) {
          _showMessage(l.cameraStartFailed);
          MeasureScreen.isRecordingOn = false;
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
    // 練習タブが動いている間は始めない（音が重なって両方おかしくなるため）
    if (PracticeScreen.isRunning) {
      _showMessage(l.practiceRunningStopFirst);
      return;
    }
    final generation = ++_startGeneration;

    // 実際に鳴らす音（BMXは毎回ランダムに待ち時間の違う音を選ぶ）
    final sound = SoundConfig.forPlay(_selectedSound);
    // スタート音のオフセット + Bluetooth補正
    final offset = sound.offsetMs + AppSettings.bluetoothOffsetMs;

    setState(() {
      _state = TimerState.countdown;
      MeasureScreen.isRunning = true;
    });
    // 別のアプリを開いても止まらないようにする
    BackgroundKeeper.start(l.appTitle, l.bgNotificationText);

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

    if (sound.assetPath != null) {
      // READYの進み具合バーを、GO!までの時間ぴったりで動かす
      _countdownStartTime = DateTime.now();
      _countdownTotalMs = offset;
      _readyController.duration = Duration(milliseconds: offset > 0 ? offset : 1);
      _readyController.forward(from: 0);

      final playStartTime = DateTime.now();
      SoundService.playStartSound(sound);
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
    BackgroundKeeper.stop();
    _timer?.cancel();
    _readyController.stop();

    // 録画中なら停止
    if (_isVideoRecording) {
      if (kIsWeb) {
        WebCameraService.stopRecording().then((_) {
          // 録画データがあれば確認ボタン付きで表示
          if (WebCameraService.hasPendingRecording()) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.cancelled),
                duration: const Duration(seconds: 10),
                action: SnackBarAction(
                  label: l.viewRecording,
                  textColor: AppTheme.volt,
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
    BackgroundKeeper.stop();

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
      _showMessage(l.registerChildFirst);
      return;
    }

    // 保存する前に、これまでの自己ベストを調べておく
    final previousBest = await DatabaseService.getAllTimeBest(_currentChildId!);

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

    // 自己ベスト更新（2本目以降で、これまでの最速より速い）
    final isPersonalBest = previousBest != null && finalTime < previousBest;
    final recordMessage = isPersonalBest
        ? l.personalBest(_formatTime(finalTime))
        : l.recordSaved(_formatTime(finalTime));
    if (isPersonalBest) {
      // 喜んでいる瞬間に、少し間をおいて App Store の評価をお願いする（iPhoneのみ・控えめに）
      Future.delayed(
        const Duration(milliseconds: 1800),
        ReviewPrompter.maybeAskAfterPersonalBest,
      );
    }

    // Web版で録画ありの場合: 「録画を確認」ボタン付きメッセージ
    if (kIsWeb && hadRecording && WebCameraService.hasPendingRecording()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(recordMessage),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: l.viewRecording,
            textColor: AppTheme.volt,
            onPressed: () {
              WebCameraService.showPendingRecording();
            },
          ),
        ),
      );
    } else {
      _showMessage(recordMessage, seconds: isPersonalBest ? 3 : 2);
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
        title: Text(l.chooseChild),
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
                      PopupMenuItem(value: 'edit', child: Text(l.rename)),
                      PopupMenuItem(
                          value: 'delete',
                          child: Text(l.delete,
                              style: const TextStyle(color: Colors.red))),
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
                title: Text(l.addNewChild),
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
        title: Text(l.rename),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l.change),
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
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteChildMessage(childName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
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
              _children.isNotEmpty ? _children.first['name'] as String : '';
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
        title: Text(l.enterChildName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.childNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l.add),
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

  /// 背景色: 待機 = 紙色 / カウントダウン = 墨色 / 計測中 = 黄緑
  Color get _backgroundColor {
    switch (_state) {
      case TimerState.waiting:
        return AppTheme.paper;
      case TimerState.countdown:
        return AppTheme.ink;
      case TimerState.measuring:
        return AppTheme.volt;
    }
  }

  /// 文字色（背景の反対色）
  Color get _foregroundColor =>
      _state == TimerState.countdown ? AppTheme.paper : AppTheme.ink;

  @override
  Widget build(BuildContext context) {
    final isWaiting = _state == TimerState.waiting;

    return Scaffold(
      // 状態ごとに画面全体の色を切り替える（遠くからでも今の状態が分かる）
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        height: double.infinity,
        color: _backgroundColor,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: isWaiting ? _buildWaiting() : _buildActive(),
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
      ),
    );
  }

  // ----------------------------------------
  //  待機中の画面（設定 + スタートボタン）
  // ----------------------------------------

  Widget _buildWaiting() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}.${today.month.toString().padLeft(2, '0')}.${today.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 上部: 日付 + 個人/チーム切替 ---
        Row(
          children: [
            Text(dateStr,
                style: AppTheme.labelStyle(
                    fontSize: 16, color: AppTheme.muted)),
            const Spacer(),
            SelectPill(
              label: l.modeSolo,
              compact: true,
              selected: !_isTeamMode,
              onTap: () => setState(() => _isTeamMode = false),
            ),
            const SizedBox(width: 6),
            SelectPill(
              label: l.modeTeam,
              compact: true,
              selected: _isTeamMode,
              onTap: () => setState(() => _isTeamMode = true),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // --- 練習する子ども ---
        Row(
          children: [
            Flexible(
              child: Text(
                _childLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _showChildSelector,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(l.change),
            ),
          ],
        ),

        // --- 中央: タイム（直前の記録が残る）。画面が狭ければ自動で縮む ---
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              // TimerText = 1文字ずつ固定幅で描いて震えを防止
              child: TimerText(
                _formatTime(_elapsedMs),
                style: AppTheme.timerStyle(fontSize: 150),
              ),
            ),
          ),
        ),

        // --- スタート音 ---
        _sectionLabel(l.startSound),
        const SizedBox(height: 6),
        SegmentedPills(
          options: SoundConfig.all
              .map((sound) =>
                  SegmentOption(sound.key, Labels.startSound(l, sound.key)))
              .toList(),
          selectedKey: _selectedSound.key,
          onChanged: (key) =>
              setState(() => _selectedSound = SoundConfig.byKey(key)),
        ),
        const SizedBox(height: 12),

        // --- 計測中BGM（走行の疾走感演出） ---
        _sectionLabel(l.runBgm),
        const SizedBox(height: 6),
        SegmentedPills(
          compact: true,
          options: MeasureBgmConfig.all
              .map((bgm) => SegmentOption(bgm.key, Labels.measureBgm(l, bgm.key)))
              .toList(),
          selectedKey: _selectedBgm.key,
          onChanged: (key) => setState(() => _selectedBgm =
              MeasureBgmConfig.all.firstWhere((b) => b.key == key)),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),

        // --- 録画スイッチ ---
        Row(
          children: [
            const Icon(Icons.videocam, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.recordVideo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Switch(
              value: _isRecordingEnabled,
              onChanged: _toggleRecording,
              activeThumbColor: Colors.white,
              activeTrackColor: AppTheme.recordRed,
            ),
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // --- Bluetooth遅延補正 ---
        Center(child: BtOffsetControl(onChanged: () => setState(() {}))),
        const SizedBox(height: 12),

        // --- スタートボタン ---
        _bigButton(
          label: 'START',
          latin: true,
          height: 76,
          background: AppTheme.ink,
          foreground: AppTheme.volt,
          onTap: _onStart,
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.muted));
  }

  // ----------------------------------------
  //  カウントダウン中・計測中の画面
  // ----------------------------------------

  Widget _buildActive() {
    final fg = _foregroundColor;
    final isMeasuring = _state == TimerState.measuring;
    final showTeamButtons = _isTeamMode && isMeasuring;

    // 見出し + 大きなタイム
    final timerBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isMeasuring ? 'GO' : 'READY',
          style: AppTheme.displayStyle(
              fontSize: 64, color: fg, letterSpacing: 2),
        ),
        TimerText(
          _formatTime(_elapsedMs),
          style: AppTheme.timerStyle(fontSize: 220, color: fg),
        ),
      ],
    );

    return Column(
      children: [
        // --- 上段: 子どもの名前 + 録画表示 ---
        Row(
          children: [
            Flexible(
              child: Text(
                _isTeamMode ? l.modeTeam : _childLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: fg),
              ),
            ),
            const Spacer(),
            if (_isVideoRecording)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fiber_manual_record,
                      size: 16, color: AppTheme.recordRed),
                  const SizedBox(width: 4),
                  Text(l.recordingNow,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: fg)),
                ],
              ),
          ],
        ),

        // --- 中央: タイム ---
        if (!showTeamButtons)
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: timerBlock),
            ),
          ),

        // --- カウントダウン中: GO!までの進み具合バー + 中止 ---
        // （BMXはいつ鳴るか分からないのが練習なので、進み具合バーは出さない）
        if (_state == TimerState.countdown) ...[
          if (_selectedSound.key == SoundConfig.bmx.key)
            const SizedBox(height: 8)
          else
          AnimatedBuilder(
            animation: _readyController,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: fg.withValues(alpha: 0.18),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _readyController.value,
                  heightFactor: 1,
                  child: ColoredBox(color: fg),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _bigButton(
            label: l.abort,
            background: Colors.transparent,
            foreground: fg,
            borderColor: fg,
            onTap: _onCancel,
          ),
        ],

        // --- 計測中（個人）: ゴールボタン ---
        if (isMeasuring && !_isTeamMode)
          _bigButton(
            label: l.goal,
            height: 104,
            fontSize: 34,
            background: AppTheme.ink,
            foreground: Colors.white,
            onTap: _onGoal,
          ),

        // --- 計測中（チーム）: 小さめのタイム + 子どもボタン ---
        if (showTeamButtons) ...[
          SizedBox(
            height: 130,
            child: FittedBox(fit: BoxFit.scaleDown, child: timerBlock),
          ),
          const SizedBox(height: 8),
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
                  onPressed:
                      isFinished ? null : () => _onTeamGoal(childId, childName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.ink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.ink.withValues(alpha: 0.12),
                    disabledForegroundColor: AppTheme.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        childName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isFinished ? 16 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isFinished)
                        Text(
                          l.teamPlace(rank, _formatTime(finishTime!)),
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          _bigButton(
            label: l.nextRace,
            height: 54,
            background: Colors.transparent,
            foreground: fg,
            borderColor: fg,
            onTap: _onCancel,
          ),
        ],
      ],
    );
  }

  /// 画面下の大きなボタン
  Widget _bigButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    Color? borderColor,
    double height = 64,
    double fontSize = 20,
    bool latin = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: latin
                  ? AppTheme.displayStyle(
                      fontSize: 34, color: foreground, letterSpacing: 3)
                  : TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: foreground,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
