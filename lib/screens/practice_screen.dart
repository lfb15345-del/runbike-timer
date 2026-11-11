import 'dart:async';
import 'dart:math' as math;
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
import '../widgets/select_pill.dart';
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

  // --- 音とタイマーの連動 ---
  // 音を鳴らすタイミングは、すべて「タイマーの残り時間」を見て決める。
  // （以前は「◯秒後に鳴らす」という予約方式だったため、一時停止すると
  //   予約だけが先に進んでしまい、音とタイマーがずれていた）

  /// 走り出してからBGMを鳴らし始めるまでの待ち時間
  /// （スタート音の余韻が消えるのを待つ）
  static const int _bgmDelayMs = 2000;

  /// この走行区間でBGMを鳴らし始めたか
  bool _bgmStarted = false;

  /// この休憩で「次のラウンドのスタート音」を鳴らし始めたか
  bool _startCueFired = false;

  /// 一時停止でスタート音を途中で止めているか（再開時に続きから鳴らす）
  bool _startSoundHeld = false;

  /// スタート音を鳴らし始めてからGO!までの時間（BT補正込み）
  int get _startLeadMs => _startSound.offsetMs + AppSettings.bluetoothOffsetMs;

  // --- アニメーション ---
  // ラスト3秒で、1秒ごとに数字を「トン」と弾ませる
  late final AnimationController _beatController;
  late final Animation<double> _beatScale;
  int _lastBeatSec = -1;

  // 最初のカウントダウン（READY）の進み具合バー
  late final AnimationController _readyController;

  @override
  void initState() {
    super.initState();
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1, // 止まっているときは等倍
    );
    _beatScale = Tween<double>(begin: 1.07, end: 1.0).animate(
      CurvedAnimation(parent: _beatController, curve: Curves.easeOutCubic),
    );
    _readyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
    _beatController.dispose();
    _readyController.dispose();
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
    // 練習中にアプリが裏に回ったら自動で一時停止する
    // （裏では音だけ止まってタイマーが進み、戻ったときに音がずれるのを防ぐ）
    if (state == AppLifecycleState.paused) {
      _onPause();
    }

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

  /// 合計時間（最後の走りのあとは休憩なしで終わる）
  String get _totalTimeDisplay {
    final totalSec = _sprintSec * _totalRounds + _restSec * (_totalRounds - 1);
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
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

    // スタート音のオフセット + BT補正 後にGO!
    final totalOffset = _startLeadMs;

    setState(() {
      _phase = PracticePhase.countdown;
      _currentRound = 1;
      _isPaused = false;
      _bgmStarted = false;
      _startCueFired = false;
      _startSoundHeld = false;
      PracticeScreen.isRunning = true;
    });
    if (_isRecordingEnabled) _recorder.resetCount();

    // READYの進み具合バーを、GO!までの時間ぴったりで動かす
    _readyController.duration =
        Duration(milliseconds: math.max(totalOffset, 1));
    _readyController.forward(from: 0);

    final playStartTime = DateTime.now();
    SoundService.playStartSound(_startSound);

    final measureStart =
        playStartTime.add(Duration(milliseconds: totalOffset));

    final waitMs = measureStart.difference(DateTime.now()).inMilliseconds;
    if (waitMs > 0) {
      await Future.delayed(Duration(milliseconds: waitMs));
    }
    // 待っている間に中止・再スタートされていたら、この古い処理は破棄する
    if (!mounted ||
        generation != _startGeneration ||
        _phase != PracticePhase.countdown) {
      return;
    }
    _startSprint();
  }

  // ========================================
  //  BGM・スタート音（タイマーに連動）
  // ========================================

  /// BGMを最初から鳴らす
  void _startBgm() {
    if (_bgmType == 'metronome') {
      SoundService.startMetronome(_metronomeBpm);
    } else if (_bgmType == 'upbeat') {
      SoundService.startUpbeat();
    }
  }

  /// タイマーの残り時間を見て、鳴らすべき音を鳴らす（タイマーが進むたびに呼ばれる）
  /// 一時停止中はタイマーが止まる = ここも呼ばれないので、音が勝手に先へ進まない
  void _syncSoundsToTimer(int remainingMs) {
    if (_phase == PracticePhase.sprint) {
      // 走り出して2秒たったらBGM開始（スタート音の余韻が消えてから）
      final elapsedMs = _sprintSec * 1000 - remainingMs;
      if (!_bgmStarted && elapsedMs >= _bgmDelayMs) {
        _bgmStarted = true;
        _startBgm();
      }
    } else if (_phase == PracticePhase.rest) {
      // 休憩の残りが「スタート音の長さ」になったら、次のラウンドのスタート音を鳴らす
      // → 休憩が0秒になる瞬間と、音声のGO!がぴったり重なる
      if (!_startCueFired &&
          _currentRound < _totalRounds &&
          remainingMs <= _startLeadMs) {
        _startCueFired = true;
        // 休憩がスタート音より短い設定のときは、音声を途中から鳴らしてGO!を合わせる
        final lateMs = _startLeadMs - remainingMs;
        SoundService.playStartSound(
          _startSound,
          fromMs: lateMs > 150 ? lateMs : 0,
        );
      }
    }
  }

  /// ラスト3秒は、1秒ごとに数字を弾ませて手にも軽く振動を返す
  void _beatOnLastSeconds(int remainingMs) {
    final wholeSec = (remainingMs / 1000).ceil();
    if (wholeSec == _lastBeatSec) return;
    _lastBeatSec = wholeSec;
    if (wholeSec <= 3) {
      _beatController.forward(from: 0);
      HapticFeedback.selectionClick();
    }
  }

  void _startSprint() {
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = PracticePhase.sprint;
      _remainingMs = _sprintSec * 1000;
      _bgmStarted = false;
      _startCueFired = false;
      _startSoundHeld = false;
      _lastBeatSec = -1;
    });
    // GO!と同時にこの区間の録画を開始
    if (_isRecordingEnabled) _recorder.start();
    // BGMは _syncSoundsToTimer が「走り出して2秒後」に鳴らす
    _startCountdownTimer();
  }

  void _startRest() {
    // 走る区間が終わったので録画を止めて保存（休憩中は録らない）
    if (_isRecordingEnabled) _recorder.stop();
    // BGM停止 → 終了の合図音
    SoundService.stopBgm();
    SoundService.playWhistle();
    HapticFeedback.mediumImpact();

    setState(() {
      _phase = PracticePhase.rest;
      _remainingMs = _restSec * 1000;
      _startCueFired = false;
      _startSoundHeld = false;
      _lastBeatSec = -1;
    });
    // 次のラウンドのスタート音は _syncSoundsToTimer が残り時間を見て鳴らす
    _startCountdownTimer();
  }

  /// 現在の残り時間からタイマーを動かす（開始・再開の両方で使う）
  void _startCountdownTimer() {
    _timer?.cancel();
    final startTime = DateTime.now();
    final initialRemaining = _remainingMs;

    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final remaining = initialRemaining - elapsed;

      if (remaining <= 0) {
        _timer?.cancel();
        _onPhaseTimeUp();
        return;
      }
      _syncSoundsToTimer(remaining);
      _beatOnLastSeconds(remaining);
      setState(() => _remainingMs = remaining);
    });
  }

  /// 走る区間・休憩区間の時間が0になったとき
  void _onPhaseTimeUp() {
    if (_phase == PracticePhase.sprint) {
      // 最後のスプリント後は休憩なしで即終了（締まる終わり方）
      if (_currentRound >= _totalRounds) {
        _onFinished();
      } else {
        _startRest();
      }
    } else if (_phase == PracticePhase.rest) {
      // 休憩後は必ず次のラウンドへ
      setState(() => _currentRound++);
      _startSprint();
    }
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
    setState(() {
      _phase = PracticePhase.finished;
      _remainingMs = 0;
      _isPaused = false;
      PracticeScreen.isRunning = false;
    });
  }

  void _onCancel() {
    _startGeneration++; // 待機中の古いスタート処理を無効にする
    _timer?.cancel();
    _readyController.stop();
    // 走行中に中止した場合も、そこまでの動画は保存する
    if (_isRecordingEnabled) {
      _recorder.stop();
      _reportSavedClips();
    }
    SoundService.stopAll(); // スタート音・BGM含め全停止
    setState(() {
      _phase = PracticePhase.idle;
      _currentRound = 1;
      _remainingMs = 0;
      _isPaused = false;
      _bgmStarted = false;
      _startCueFired = false;
      _startSoundHeld = false;
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

  /// 一時停止（走行中・休憩中のみ）: タイマーと音をまとめて止めて現状維持
  void _onPause() {
    if (_phase != PracticePhase.sprint && _phase != PracticePhase.rest) return;
    if (_isPaused) return;
    _timer?.cancel();
    SoundService.pauseBgm();
    if (_phase == PracticePhase.rest && _startCueFired) {
      // 次のラウンドのスタート音が鳴っている最中 → 音も一緒に止めておく
      SoundService.pauseStartSound();
      _startSoundHeld = true;
    } else if (_phase == PracticePhase.sprint) {
      // GO!直後に残っているスタート音の余韻は止める（再開時には鳴らさない）
      SoundService.stopStartSound();
    }
    // 走行中に一時停止したら録画も止めて保存（再開後は次の走りから録る）
    if (_isRecordingEnabled && _phase == PracticePhase.sprint) {
      _recorder.stop();
    }
    setState(() => _isPaused = true);
  }

  /// 一時停止からの再開: 残り時間の続きから、タイマーと音を同時に再開
  void _onResume() {
    if (!_isPaused) return;
    setState(() => _isPaused = false);
    if (_phase == PracticePhase.sprint && _bgmStarted) {
      // すでに鳴り始めていたBGMを再開
      // （まだ鳴っていなかった場合は、タイマーが2秒地点に来たとき自動で鳴る）
      if (_bgmType == 'metronome') {
        SoundService.startMetronome(_metronomeBpm);
      } else if (_bgmType == 'upbeat') {
        SoundService.resumeUpbeat(); // 曲の続きから
      }
    }
    if (_startSoundHeld) {
      // 止めておいたスタート音を続きから（タイマーと同時に再開するのでGO!がずれない）
      _startSoundHeld = false;
      SoundService.resumeStartSound();
    }
    _startCountdownTimer(); // 現在の残り時間から再開
  }

  // ========================================
  //  画面の色（状態ごとに背景色を丸ごと切り替える）
  // ========================================

  bool get _isLastSeconds =>
      (_phase == PracticePhase.sprint || _phase == PracticePhase.rest) &&
      _remainingMs <= 3000;

  /// 背景色: 走る=黄緑 / 走るラスト3秒=オレンジ / 休む・READY=墨色 / 設定・終了=紙色
  Color get _backgroundColor {
    switch (_phase) {
      case PracticePhase.countdown:
      case PracticePhase.rest:
        return AppTheme.ink;
      case PracticePhase.sprint:
        return _isLastSeconds ? AppTheme.signal : AppTheme.volt;
      case PracticePhase.idle:
      case PracticePhase.finished:
        return AppTheme.paper;
    }
  }

  /// 文字色（背景の反対色）
  Color get _foregroundColor {
    final onDark = _phase == PracticePhase.countdown ||
        _phase == PracticePhase.rest;
    return onDark ? AppTheme.paper : AppTheme.ink;
  }

  // ========================================
  //  UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    final isIdle = _phase == PracticePhase.idle;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        height: double.infinity,
        color: _backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(child: isIdle ? _buildSetup() : _buildRunning()),
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
      ),
    );
  }

  // ----------------------------------------
  //  設定画面（スタート前）
  // ----------------------------------------

  Widget _buildSetup() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 見出し + 合計時間
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('INTERVAL',
                              style: AppTheme.labelStyle(
                                  fontSize: 14, color: AppTheme.muted)),
                          const SizedBox(height: 4),
                          const Text('インターバル練習',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('合計',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.muted)),
                        Text(_totalTimeDisplay,
                            style: AppTheme.timerStyle(fontSize: 34)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 走る・休む・回数
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _stepper('走る', _sprintSec, '秒', onMinus: () {
                          if (_sprintSec > 5) setState(() => _sprintSec -= 5);
                        }, onPlus: () {
                          if (_sprintSec < 60) setState(() => _sprintSec += 5);
                        }),
                      ),
                      Container(width: 1, height: 72, color: AppTheme.line),
                      Expanded(
                        child: _stepper('休む', _restSec, '秒', onMinus: () {
                          if (_restSec > 5) setState(() => _restSec -= 5);
                        }, onPlus: () {
                          if (_restSec < 120) setState(() => _restSec += 5);
                        }),
                      ),
                      Container(width: 1, height: 72, color: AppTheme.line),
                      Expanded(
                        child: _stepper('回数', _totalRounds, '回', onMinus: () {
                          if (_totalRounds > 1) setState(() => _totalRounds--);
                        }, onPlus: () {
                          if (_totalRounds < 20) setState(() => _totalRounds++);
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 練習メニューの帯（黒 = 走る / グレー = 休む）
                _buildPlanStrip(),
                const SizedBox(height: 20),

                // BGM設定
                const Text('走行中BGM',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _bgmPill('無音', 'none', Icons.volume_off),
                    _bgmPill('メトロノーム', 'metronome', Icons.music_note),
                    _bgmPill('アップテンポ', 'upbeat', Icons.audiotrack),
                  ],
                ),
                // メトロノームBPMスライダー
                if (_bgmType == 'metronome')
                  Row(
                    children: [
                      Text('BPM',
                          style: AppTheme.labelStyle(
                              fontSize: 14, color: AppTheme.muted)),
                      Expanded(
                        child: Slider(
                          value: _metronomeBpm.toDouble(),
                          min: 150,
                          max: 300,
                          divisions: 30,
                          label: '$_metronomeBpm',
                          onChanged: (v) =>
                              setState(() => _metronomeBpm = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text('$_metronomeBpm',
                            textAlign: TextAlign.right,
                            style: AppTheme.timerStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                const Divider(height: 1),

                // 録画（走る区間ごとに1本ずつ写真アプリへ。Web版は非対応）
                if (!kIsWeb) ...[
                  Row(
                    children: [
                      const Icon(Icons.videocam, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('走るたびに録画',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      Switch(
                        value: _isRecordingEnabled,
                        onChanged: _toggleRecording,
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                ],
                const SizedBox(height: 10),
                // Bluetooth遅延補正（計測タブと共有、共通ウィジェット）
                BtOffsetControl(onChanged: () => setState(() {})),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: _bigButton(
            label: 'START',
            background: AppTheme.ink,
            foreground: AppTheme.volt,
            onTap: _onStart,
          ),
        ),
      ],
    );
  }

  /// 設定の増減コントロール（大きな数字 + −/＋ボタン）
  Widget _stepper(
    String label,
    int value,
    String unit, {
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.muted)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$value', style: AppTheme.timerStyle(fontSize: 46)),
            const SizedBox(width: 2),
            Text(unit,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roundIconButton(Icons.remove, onMinus),
            const SizedBox(width: 8),
            _roundIconButton(Icons.add, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _roundIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppTheme.paper,
      shape: const CircleBorder(side: BorderSide(color: AppTheme.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: AppTheme.ink),
        ),
      ),
    );
  }

  /// 練習メニュー全体を1本の帯で見せる（黒 = 走る / グレー = 休む）
  Widget _buildPlanStrip() {
    final segments = <Widget>[];
    for (var i = 0; i < _totalRounds; i++) {
      segments.add(Expanded(
        flex: _sprintSec,
        child: Container(height: 12, color: AppTheme.ink),
      ));
      if (i < _totalRounds - 1) {
        segments.add(Expanded(
          flex: _restSec,
          child: Container(
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: AppTheme.line,
          ),
        ));
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(children: segments),
    );
  }

  Widget _bgmPill(String label, String type, IconData icon) {
    return SelectPill(
      label: label,
      icon: icon,
      selected: _bgmType == type,
      onTap: () => setState(() => _bgmType = type),
    );
  }

  // ----------------------------------------
  //  練習中の画面（READY / GO / REST / FINISH）
  // ----------------------------------------

  Widget _buildRunning() {
    final fg = _foregroundColor;

    // 上の区切りバー用: 走り終えた本数と、いま走っている1本の進み具合
    int completedRounds = 0;
    double currentFill = 0;
    if (_phase == PracticePhase.sprint) {
      completedRounds = _currentRound - 1;
      currentFill = 1 - _remainingMs / (_sprintSec * 1000);
    } else if (_phase == PracticePhase.rest) {
      completedRounds = _currentRound;
    } else if (_phase == PracticePhase.finished) {
      completedRounds = _totalRounds;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          // --- 上段: ラウンド + 状態 ---
          Row(
            children: [
              Text(
                'ROUND $_currentRound / $_totalRounds',
                style: AppTheme.labelStyle(fontSize: 20, color: fg),
              ),
              const Spacer(),
              if (_isPaused)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: fg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('一時停止中',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _backgroundColor)),
                )
              else if (_isRecordingEnabled)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _recorder.isRecording
                          ? Icons.fiber_manual_record
                          : Icons.videocam,
                      size: 16,
                      color: _recorder.isRecording ? AppTheme.recordRed : fg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _recorder.isRecording
                          ? '録画中 ・ 保存 ${_recorder.savedCount}本'
                          : '保存 ${_recorder.savedCount}本',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fg),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _RoundSegments(
            total: _totalRounds,
            completed: completedRounds,
            currentFill: currentFill.clamp(0.0, 1.0).toDouble(),
            color: fg,
          ),

          // --- 中央: 状態の見出し + 大きな残り秒数 ---
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildCenter(fg),
              ),
            ),
          ),

          // --- 下段: この区間の残り時間バー + ボタン ---
          _buildPhaseBar(fg),
          const SizedBox(height: 16),
          _buildButtons(fg),
        ],
      ),
    );
  }

  /// 画面中央（見出し + 数字）
  Widget _buildCenter(Color fg) {
    String word = '';
    String caption = '';
    if (_phase == PracticePhase.countdown) {
      word = 'READY';
      caption = 'スタート音のあとに走り出す';
    } else if (_phase == PracticePhase.sprint) {
      word = 'GO';
      caption = _currentRound >= _totalRounds ? 'ラスト1本！' : '走る';
    } else if (_phase == PracticePhase.rest) {
      word = 'REST';
      caption = 'つぎは ${_currentRound + 1}本目';
    } else if (_phase == PracticePhase.finished) {
      word = 'FINISH';
      caption = '$_totalRounds本 おつかれさま！';
    }

    final showDigits =
        _phase == PracticePhase.sprint || _phase == PracticePhase.rest;
    final digitText = _formatRemaining(_remainingMs);
    // 数字の桁数が変わっても全体の大きさが変わらないよう、最低「00.0」の幅を確保する
    const digitSize = 220.0;
    final digitCount = math.max(digitText.length - 1, 3);
    final digitBoxWidth = digitSize * (0.52 * digitCount + 0.26);
    // 休憩のラスト3秒は数字を黄緑にして「もうすぐ走る」を知らせる
    final digitColor =
        _phase == PracticePhase.rest && _isLastSeconds ? AppTheme.volt : fg;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 見出しは状態が変わるたびに下からスッと入れ替わる
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.35),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            word,
            key: ValueKey<PracticePhase>(_phase),
            style: AppTheme.displayStyle(
              fontSize: showDigits ? 64 : 120,
              color: fg,
              letterSpacing: 2,
            ),
          ),
        ),
        if (showDigits)
          Opacity(
            opacity: _isPaused ? 0.35 : 1,
            child: ScaleTransition(
              scale: _beatScale,
              child: SizedBox(
                width: digitBoxWidth,
                child: Center(
                  child: TimerText(
                    digitText,
                    style: AppTheme.timerStyle(
                        fontSize: digitSize, color: digitColor),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          caption,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  /// この区間の残り時間バー（READY中はGO!に向かって伸び、走る・休むは減っていく）
  Widget _buildPhaseBar(Color fg) {
    if (_phase == PracticePhase.countdown) {
      return AnimatedBuilder(
        animation: _readyController,
        builder: (context, _) => _bar(fg, _readyController.value),
      );
    }
    if (_phase == PracticePhase.sprint || _phase == PracticePhase.rest) {
      final totalMs =
          (_phase == PracticePhase.sprint ? _sprintSec : _restSec) * 1000;
      return _bar(fg, (_remainingMs / totalMs).clamp(0.0, 1.0).toDouble());
    }
    return const SizedBox(height: 8);
  }

  Widget _bar(Color fg, double fraction) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        color: fg.withValues(alpha: 0.18),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          heightFactor: 1,
          child: ColoredBox(color: fg),
        ),
      ),
    );
  }

  /// 下のボタン（背景色に合わせて、文字色のベタ塗り or 枠線だけで描く）
  Widget _buildButtons(Color fg) {
    if (_phase == PracticePhase.countdown) {
      // カウントダウン中は中止のみ（スタート音再生中のため一時停止は不可）
      return _bigButton(
        label: 'STOP',
        background: Colors.transparent,
        foreground: fg,
        borderColor: fg,
        onTap: _onCancel,
      );
    }
    if (_phase == PracticePhase.sprint || _phase == PracticePhase.rest) {
      // 一時停止（または再開）と STOP を横並びで表示
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: _bigButton(
              label: _isPaused ? '再開' : '一時停止',
              icon: _isPaused ? Icons.play_arrow : Icons.pause,
              latin: false,
              background: fg,
              foreground: _backgroundColor,
              onTap: _isPaused ? _onResume : _onPause,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _bigButton(
              label: 'STOP',
              background: Colors.transparent,
              foreground: fg,
              borderColor: fg,
              onTap: _onCancel,
            ),
          ),
        ],
      );
    }
    // 終了画面
    return _bigButton(
      label: 'RESET',
      background: AppTheme.ink,
      foreground: AppTheme.volt,
      onTap: _onReset,
    );
  }

  /// 画面下の大きなボタン
  Widget _bigButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    Color? borderColor,
    IconData? icon,
    bool latin = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 26, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: latin
                      ? AppTheme.displayStyle(
                          fontSize: 30,
                          color: foreground,
                          letterSpacing: 3,
                        )
                      : TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: foreground,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ラウンドの区切りバー（1マス = 1本。走り終えたマスが塗られていく）
class _RoundSegments extends StatelessWidget {
  final int total;

  /// 走り終えた本数
  final int completed;

  /// いま走っている1本の進み具合（0.0〜1.0）
  final double currentFill;
  final Color color;

  const _RoundSegments({
    required this.total,
    required this.completed,
    required this.currentFill,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  color: color.withValues(alpha: 0.2),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: i < completed
                        ? 1.0
                        : (i == completed ? currentFill : 0.0),
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
