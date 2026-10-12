import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../constants/sound_config.dart';
import '../services/sound_service.dart';
import '../services/app_settings.dart';
import '../services/practice_recorder.dart';
import '../services/video_saver.dart';
import '../widgets/bt_offset_control.dart';
import '../widgets/camera_wipe.dart';
import '../widgets/timer_text.dart';
import '../theme.dart';

/// インターバル練習の状態
enum PracticePhase { idle, countdown, sprint, rest, finished }

/// インターバル練習タブ（タバタ風）
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  /// 他の画面からチェック用（練習中はタブ切替をブロック）
  static bool isRunning = false;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // --- 録画（走る区間ごとに1本ずつ。ネイティブ版のみ） ---
  bool _isRecordingEnabled = false;
  final PracticeRecorder _recorder = PracticeRecorder();

  // --- 練習設定 ---
  int _sprintSec = 20;
  int _restSec = 40;
  int _totalRounds = 8;

  // --- BGM設定 ---
  // デフォルトはアップテンポBGM（走行中の盛り上げと、沈黙を感じさせないため）
  String _bgmType = 'upbeat'; // none, metronome, upbeat
  int _metronomeBpm = 180;

  // --- 状態管理 ---
  PracticePhase _phase = PracticePhase.idle;

  // スタートの世代番号（連打や「中止→即再スタート」で古い処理が生き残るのを防ぐ）
  int _startGeneration = 0;

  // 一時停止中かどうか（走行中・休憩中のみ一時停止できる）
  bool _isPaused = false;
  int _currentRound = 1;
  int _remainingMs = 0;
  Timer? _timer;

  // --- 音声（練習では「基本」スタート音を使用、定義は SoundConfig に一元化） ---
  static const StartSound _startSound = SoundConfig.basic;

  // --- アニメーション ---
  late AnimationController _speedLineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speedLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    SoundService.preloadStartSounds();
    WidgetsBinding.instance.addObserver(this);
    _recorder.addListener(_onRecorderChanged);
    AppSettings.currentTab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    SoundService.stopAll();
    WidgetsBinding.instance.removeObserver(this);
    AppSettings.currentTab.removeListener(_onTabChanged);
    _recorder.removeListener(_onRecorderChanged);
    _recorder.dispose();
    _speedLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ========================================
  //  録画（ネイティブ版のみ）
  // ========================================

  void _onRecorderChanged() {
    if (mounted) setState(() {});
  }

  /// 録画スイッチのON/OFF（ONの間はカメラ映像の小窓が出る）
  void _toggleRecording(bool value) {
    setState(() => _isRecordingEnabled = value);
    if (value) {
      _recorder.open();
    } else {
      _recorder.close();
    }
  }

  /// 練習タブを離れたらカメラを手放し、戻ってきたら付け直す
  /// （計測タブも同じカメラを使うため、同時に持たないようにする）
  void _onTabChanged() {
    if (!_isRecordingEnabled) return;
    if (AppSettings.currentTab.value == 1) {
      _recorder.open();
    } else {
      _recorder.close();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRecordingEnabled) return;
    // 「paused」= ホームに戻った等。カメラ許可ダイアログ表示中（inactive）では閉じない
    if (state == AppLifecycleState.paused) {
      _recorder.close();
    } else if (state == AppLifecycleState.resumed &&
        AppSettings.currentTab.value == 1) {
      _recorder.open();
    }
  }

  /// 練習終了・中止のあとに、保存した動画の本数を知らせる
  Future<void> _reportSavedClips() async {
    if (!_isRecordingEnabled) return;
    await _recorder.waitIdle();
    if (!mounted) return;
    final String? msg;
    if (_recorder.accessDenied) {
      msg = VideoSaver.deniedMessage;
    } else if (_recorder.savedCount > 0) {
      msg = '走りの動画を${_recorder.savedCount}本、写真アプリに保存しました'
          '（アルバム「ランバイクタイマー」）';
    } else {
      msg = null;
    }
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: Duration(seconds: _recorder.accessDenied ? 8 : 4),
    ));
  }

  /// 合計時間を計算
  String get _totalTimeDisplay {
    final totalSec = (_sprintSec + _restSec) * _totalRounds;
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    return '$min分${sec.toString().padLeft(2, '0')}秒';
  }

  /// 残り秒数を表示用に変換
  String _formatRemaining(int ms) {
    final sec = ms / 1000;
    return sec.toStringAsFixed(1);
  }

  // ========================================
  //  スタート・フェーズ制御
  // ========================================

  Future<void> _onStart() async {
    // 連打防止: 待機中でなければ受け付けない（画面が切り替わる前の2度押し対策）
    if (_phase != PracticePhase.idle) return;
    final generation = ++_startGeneration;

    setState(() {
      _phase = PracticePhase.countdown;
      _currentRound = 1;
      _isPaused = false;
      PracticeScreen.isRunning = true;
    });
    if (_isRecordingEnabled) _recorder.resetCount();

    final playStartTime = DateTime.now();
    SoundService.playStartSound(_startSound);

    // スタート音のオフセット + BT補正 後にGO!
    final totalOffset = _startSound.offsetMs + AppSettings.bluetoothOffsetMs;
    final measureStart =
        playStartTime.add(Duration(milliseconds: totalOffset));

    final waitMs = measureStart.difference(DateTime.now()).inMilliseconds;
    if (waitMs > 0) {
      await Future.delayed(Duration(milliseconds: waitMs));
    }
    // 待っている間に中止・再スタートされていたら、この古い処理は破棄する
    if (generation != _startGeneration || _phase != PracticePhase.countdown) {
      return;
    }
    _startSprint();
  }

  // ========================================
  //  BGM制御
  // ========================================

  /// BGMを開始（走行フェーズ開始時に呼ぶ）
  void _startBgm() {
    if (_bgmType == 'metronome') {
      SoundService.startMetronome(_metronomeBpm);
    } else if (_bgmType == 'upbeat') {
      SoundService.startUpbeat();
    }
  }

  void _startSprint() {
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = PracticePhase.sprint;
      _remainingMs = _sprintSec * 1000;
    });
    // GO!と同時にこの区間の録画を開始
    if (_isRecordingEnabled) _recorder.start();
    // ビープ音（start02.mp3）のGO!直後 → ホイッスルは鳴らさない
    // ビープ音の余韻が完全に消えてからBGM開始（2秒待つ）
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_phase == PracticePhase.sprint && !_isPaused) _startBgm();
    });
    _startCountdownTimer();
  }

  void _startRest() {
    // 走る区間が終わったので録画を止めて保存（休憩中は録らない）
    if (_isRecordingEnabled) _recorder.stop();
    // BGM停止 → ホイッスル音
    SoundService.stopBgm();
    SoundService.playWhistle();
    HapticFeedback.mediumImpact();

    setState(() {
      _phase = PracticePhase.rest;
      _remainingMs = _restSec * 1000;
    });
    _startCountdownTimer();

    // 休憩の最後にスタート音を再生（次ラウンドのカウントダウン）
    if (_currentRound < _totalRounds) {
      final nextTotalOffset = _startSound.offsetMs + AppSettings.bluetoothOffsetMs;
      final soundDelay = (_restSec * 1000) - nextTotalOffset;
      if (soundDelay > 0) {
        Future.delayed(Duration(milliseconds: soundDelay), () {
          if (_phase == PracticePhase.rest) {
            SoundService.playStartSound(_startSound);
          }
        });
      }
    }
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    final startTime = DateTime.now();
    final initialRemaining = _remainingMs;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final remaining = initialRemaining - elapsed;

      if (remaining <= 0) {
        _timer?.cancel();
        if (_phase == PracticePhase.sprint) {
          // 最後のスプリント後は休憩なしで即終了（締まる終わり方）
          if (_currentRound >= _totalRounds) {
            _onFinished();
          } else {
            _startRest();
          }
        } else if (_phase == PracticePhase.rest) {
          // 休憩後は必ず次のラウンドへ（最後の休憩は上のロジックで発生しない）
          setState(() => _currentRound++);
          _startSprint();
        }
      } else {
        if (remaining <= 3000 && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
        if (remaining > 3000 && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.reset();
        }
        setState(() => _remainingMs = remaining);
      }
    });
  }

  void _onFinished() {
    _timer?.cancel();
    if (_isRecordingEnabled) {
      _recorder.stop();
      _reportSavedClips();
    }
    SoundService.stopBgm();
    SoundService.playWhistle();
    HapticFeedback.heavyImpact();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _phase = PracticePhase.finished;
      _remainingMs = 0;
      PracticeScreen.isRunning = false;
    });
  }

  void _onCancel() {
    _timer?.cancel();
    // 走行中に中止した場合も、そこまでの動画は保存する
    if (_isRecordingEnabled) {
      _recorder.stop();
      _reportSavedClips();
    }
    SoundService.stopAll(); // スタート音・BGM含め全停止
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _phase = PracticePhase.idle;
      _currentRound = 1;
      _remainingMs = 0;
      _isPaused = false;
      PracticeScreen.isRunning = false;
    });
  }

  void _onReset() {
    setState(() {
      _phase = PracticePhase.idle;
      _currentRound = 1;
      _remainingMs = 0;
      _isPaused = false;
      PracticeScreen.isRunning = false;
    });
  }

  /// 一時停止（走行中・休憩中のみ）: タイマーとBGMを止めて現状維持
  void _onPause() {
    if (_phase != PracticePhase.sprint && _phase != PracticePhase.rest) return;
    if (_isPaused) return;
    _timer?.cancel();
    SoundService.pauseBgm();
    _pulseController.stop();
    // 走行中に一時停止したら録画も止めて保存（再開後は次の走りから録る）
    if (_isRecordingEnabled && _phase == PracticePhase.sprint) {
      _recorder.stop();
    }
    setState(() => _isPaused = true);
  }

  /// 一時停止からの再開: 残り時間の続きからタイマーとBGMを再開
  void _onResume() {
    if (!_isPaused) return;
    setState(() => _isPaused = false);
    // BGMを再開（走行中のみ。休憩中はもともとBGMなし）
    if (_phase == PracticePhase.sprint) {
      if (_bgmType == 'metronome') {
        SoundService.startMetronome(_metronomeBpm);
      } else if (_bgmType == 'upbeat') {
        SoundService.resumeUpbeat(); // 曲の続きから
      }
    }
    _startCountdownTimer(); // 現在の残り時間から再開
  }

  double get _overallProgress {
    if (_phase == PracticePhase.idle || _phase == PracticePhase.countdown) {
      return 0;
    }
    if (_phase == PracticePhase.finished) return 1;

    final roundMs = (_sprintSec + _restSec) * 1000;
    final totalMs = roundMs * _totalRounds;
    final completedMs = (_currentRound - 1) * roundMs;
    final currentPhaseTotal =
        (_phase == PracticePhase.sprint ? _sprintSec : _restSec) * 1000;
    final currentPhaseElapsed = currentPhaseTotal - _remainingMs;
    final prevPhaseMs =
        _phase == PracticePhase.rest ? _sprintSec * 1000 : 0;

    return (completedMs + prevPhaseMs + currentPhaseElapsed) / totalMs;
  }

  // ========================================
  //  UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    final isRunning = _phase != PracticePhase.idle;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (!isRunning) _buildSettings(),
                Expanded(child: _buildMainArea()),
                _buildButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // カメラ映像の小窓（録画ON時のみ。録画中は赤枠になる）
          if (!kIsWeb && _isRecordingEnabled && _recorder.isReady)
            CameraWipe(
              controller: _recorder.controller!,
              isRecording: _recorder.isRecording,
              zoom: _recorder.zoom,
              onZoomRequest: _recorder.setZoom,
              onSwitchCamera: _recorder.switchCamera,
            ),
        ],
      ),
    );
  }

  /// 設定パネル（コンパクト版）
  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Column(
        children: [
          const Text('インターバル練習',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // 3つの設定を横並び（コンパクト）
          Row(
            children: [
              Expanded(child: _settingControl('走る', _sprintSec, '秒',
                  onMinus: () {
                    if (_sprintSec > 5) setState(() => _sprintSec -= 5);
                  },
                  onPlus: () {
                    if (_sprintSec < 60) setState(() => _sprintSec += 5);
                  })),
              Expanded(child: _settingControl('休む', _restSec, '秒',
                  onMinus: () {
                    if (_restSec > 5) setState(() => _restSec -= 5);
                  },
                  onPlus: () {
                    if (_restSec < 120) setState(() => _restSec += 5);
                  })),
              Expanded(child: _settingControl('回数', _totalRounds, '回',
                  onMinus: () {
                    if (_totalRounds > 1) setState(() => _totalRounds--);
                  },
                  onPlus: () {
                    if (_totalRounds < 20) setState(() => _totalRounds++);
                  })),
            ],
          ),
          const SizedBox(height: 8),
          Text('合計 $_totalTimeDisplay',
              style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          const Divider(height: 20),
          // BGM設定
          const Text('走行中BGM', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bgmChip('無音', 'none', Icons.volume_off),
              const SizedBox(width: 8),
              _bgmChip('メトロノーム', 'metronome', Icons.music_note),
              const SizedBox(width: 8),
              _bgmChip('アップテンポ', 'upbeat', Icons.audiotrack),
            ],
          ),
          // メトロノームBPMスライダー
          if (_bgmType == 'metronome') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 8),
                Text('BPM', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Expanded(
                  child: Slider(
                    value: _metronomeBpm.toDouble(),
                    min: 150,
                    max: 300,
                    divisions: 30,
                    label: '$_metronomeBpm',
                    onChanged: (v) => setState(() => _metronomeBpm = v.round()),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text('$_metronomeBpm',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          // 録画（走る区間ごとに1本ずつ写真アプリへ。Web版は非対応）
          if (!kIsWeb) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, size: 20),
                const SizedBox(width: 6),
                const Text('走るたびに録画', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Switch(
                  value: _isRecordingEnabled,
                  onChanged: _toggleRecording,
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          // Bluetooth遅延補正（計測タブと共有、共通ウィジェット）
          BtOffsetControl(onChanged: () => setState(() {})),
        ],
      ),
    );
  }

  Widget _bgmChip(String label, String type, IconData icon) {
    final selected = _bgmType == type;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : null),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13,
              color: selected ? Colors.white : null)),
        ],
      ),
      selected: selected,
      selectedColor: Colors.green,
      onSelected: (_) => setState(() => _bgmType = type),
    );
  }

  /// 設定コントロール（コンパクト版）
  Widget _settingControl(
    String label, int value, String unit, {
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32, height: 32,
              child: IconButton(
                onPressed: onMinus,
                icon: const Icon(Icons.remove_circle_outline, size: 22),
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('$value$unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: 32, height: 32,
              child: IconButton(
                onPressed: onPlus,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// メインエリア
  Widget _buildMainArea() {
    if (_phase == PracticePhase.idle) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bike, size: 80,
                color: Colors.green[400]),
            const SizedBox(height: 16),
            Text('設定してスタート',
                style: TextStyle(fontSize: 18, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ClipRect(
      child: Stack(
        children: [
          // 背景グラデーション
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _phaseGradient,
              ),
            ),
          ),

          // 走行中エフェクト（横方向スピードライン）
          if (_phase == PracticePhase.sprint)
            AnimatedBuilder(
              animation: _speedLineController,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: _HorizontalSpeedPainter(
                  progress: _speedLineController.value,
                ),
              ),
            ),

          // 休憩中エフェクト（ゆっくり漂う光）
          if (_phase == PracticePhase.rest)
            AnimatedBuilder(
              animation: _speedLineController,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: _FloatingLightPainter(
                  progress: _speedLineController.value,
                ),
              ),
            ),

          // メインコンテンツ
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // フェーズ表示
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _remainingMs <= 3000 &&
                            _phase != PracticePhase.finished &&
                            _phase != PracticePhase.countdown
                        ? 1.0 + _pulseController.value * 0.12
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: _buildPhaseDisplay(),
                    );
                  },
                ),
                const SizedBox(height: 4),

                // カウントダウン数字
                if (_phase == PracticePhase.sprint ||
                    _phase == PracticePhase.rest)
                  // TimerText = 1文字ずつ固定幅で描いて震えを防止
                  // FittedBoxで1行のまま画面幅に収める（改行・はみ出し防止）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TimerText(
                        _formatRemaining(_remainingMs),
                        style: TextStyle(
                          fontSize: 84,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Orbitron',
                          color: _remainingMs <= 3000
                              ? Colors.yellow
                              : Colors.white,
                          shadows: const [
                            Shadow(blurRadius: 16, color: Colors.black54,
                                offset: Offset(2, 3)),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_phase == PracticePhase.finished)
                  const Text('FINISH!!',
                      style: TextStyle(fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(blurRadius: 16, color: Colors.black45,
                                offset: Offset(2, 3)),
                          ])),

                const SizedBox(height: 20),

                // ラウンド
                if (_phase != PracticePhase.finished)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ROUND $_currentRound / $_totalRounds',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Orbitron',
                          letterSpacing: 2),
                    ),
                  ),

                const SizedBox(height: 24),

                // 進捗バー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _overallProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _phase == PracticePhase.finished
                            ? Colors.amber
                            : Colors.white,
                      ),
                    ),
                  ),
                ),

                // 録画ON時: 保存済みの本数
                if (_isRecordingEnabled) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _recorder.isRecording
                            ? Icons.fiber_manual_record
                            : Icons.videocam,
                        size: 18,
                        color: _recorder.isRecording
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _recorder.isRecording
                            ? '録画中  ・  保存 ${_recorder.savedCount}本'
                            : '保存 ${_recorder.savedCount}本',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// フェーズ表示ウィジェット
  Widget _buildPhaseDisplay() {
    switch (_phase) {
      case PracticePhase.countdown:
        return const Text('READY',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                fontFamily: 'Orbitron',
                color: Colors.white70, letterSpacing: 8,
                shadows: [Shadow(blurRadius: 10, color: Colors.black38)]));
      case PracticePhase.sprint:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department,
                size: 36,
                color: _remainingMs <= 3000 ? Colors.yellow : Colors.orangeAccent),
            const SizedBox(width: 8),
            Text('GO',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900,
                    fontFamily: 'Orbitron',
                    color: _remainingMs <= 3000 ? Colors.yellow : Colors.white,
                    letterSpacing: 6,
                    shadows: const [Shadow(blurRadius: 12, color: Colors.black54,
                        offset: Offset(2, 2))])),
            const SizedBox(width: 8),
            Icon(Icons.local_fire_department,
                size: 36,
                color: _remainingMs <= 3000 ? Colors.yellow : Colors.orangeAccent),
          ],
        );
      case PracticePhase.rest:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.air, size: 32, color: Colors.white70),
            const SizedBox(width: 8),
            Text('BREAK',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                    fontFamily: 'Orbitron',
                    color: _remainingMs <= 3000 ? Colors.yellow : Colors.white,
                    letterSpacing: 4,
                    shadows: const [Shadow(blurRadius: 10, color: Colors.black38)])),
          ],
        );
      case PracticePhase.finished:
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  List<Color> get _phaseGradient {
    switch (_phase) {
      case PracticePhase.countdown:
        return [const Color(0xFF1a1a2e), const Color(0xFF16213e)];
      case PracticePhase.sprint:
        return _remainingMs <= 3000
            ? [const Color(0xFFb71c1c), const Color(0xFF880e4f)]
            : [const Color(0xFF1b5e20), const Color(0xFF004d40)];
      case PracticePhase.rest:
        return _remainingMs <= 3000
            ? [const Color(0xFFe65100), const Color(0xFFbf360c)]
            : [const Color(0xFF0d47a1), const Color(0xFF1a237e)];
      case PracticePhase.finished:
        return [const Color(0xFFf57f17), const Color(0xFFe65100)];
      default:
        return [Colors.grey[200]!, Colors.grey[300]!];
    }
  }

  Widget _buildButtons() {
    switch (_phase) {
      case PracticePhase.idle:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: _onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('START',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron', letterSpacing: 4)),
            ),
          ),
        );
      case PracticePhase.countdown:
        // カウントダウン中は中止のみ（スタート音再生中のため一時停止は不可）
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: _onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('STOP',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron', letterSpacing: 4)),
            ),
          ),
        );
      case PracticePhase.sprint:
      case PracticePhase.rest:
        // 一時停止（または再開）と STOP を横並びで表示
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _isPaused ? _onResume : _onPause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaused
                          ? AppTheme.accentAmber
                          : Colors.blueGrey[700],
                      foregroundColor: _isPaused
                          ? const Color(0xFF072016)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause,
                        size: 26),
                    label: Text(_isPaused ? '再開' : '一時停止',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('STOP',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron', letterSpacing: 3)),
                  ),
                ),
              ),
            ],
          ),
        );
      case PracticePhase.finished:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: _onReset,
              style: ElevatedButton.styleFrom(
                // ブランドのアンバー（チェッカーフラッグの金色）でレース感を統一
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: const Color(0xFF072016),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('RESET',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron', letterSpacing: 4)),
            ),
          ),
        );
    }
  }
}

// ========================================
//  横方向スピードライン（走行中）
// ========================================
class _HorizontalSpeedPainter extends CustomPainter {
  final double progress;

  _HorizontalSpeedPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // 水平方向の流れるライン
    for (int i = 0; i < 25; i++) {
      final seed = i * 137.5;
      final y = (seed % size.height);
      final xStart = ((seed * 3.7 + progress * size.width * 2) % (size.width * 1.5)) - size.width * 0.3;
      final lineLen = 40.0 + (i % 5) * 30;
      final thickness = 1.0 + (i % 3) * 1.5;
      final alpha = 40 + (i % 4) * 25;

      paint.strokeWidth = thickness;
      paint.color = Colors.white.withAlpha(alpha);

      canvas.drawLine(
        Offset(xStart, y),
        Offset(xStart + lineLen, y),
        paint,
      );
    }

    // 光の粒子（横に流れる）
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 20; i++) {
      final seed = i * 89.3;
      final y = (seed * 4.1) % size.height;
      final x = ((seed * 2.3 + progress * size.width * 3) % (size.width * 1.4)) - size.width * 0.2;
      final radius = 1.5 + (i % 3) * 1.2;
      final alpha = 60 + (i % 5) * 20;

      paint.color = Colors.greenAccent.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalSpeedPainter old) =>
      old.progress != progress;
}

// ========================================
//  漂う光（休憩中）
// ========================================
class _FloatingLightPainter extends CustomPainter {
  final double progress;

  _FloatingLightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 + progress * 60) * pi / 180;
      final dist = 60.0 + (i % 4) * 40 + sin(progress * 2 * pi + i) * 20;
      final x = cx + cos(angle) * dist;
      final y = cy + sin(angle) * dist;
      final radius = 3.0 + (i % 3) * 2;
      final alpha = 30 + (i % 4) * 15;

      paint.color = Colors.lightBlueAccent.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingLightPainter old) =>
      old.progress != progress;
}
