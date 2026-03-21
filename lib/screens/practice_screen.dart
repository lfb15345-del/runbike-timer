import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// インターバル練習の状態
enum PracticePhase { idle, countdown, sprint, rest, finished }

/// インターバル練習タブ（タバタ風）
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  // --- 練習設定 ---
  int _sprintSec = 20;
  int _restSec = 40;
  int _totalRounds = 8;

  // --- 状態管理 ---
  PracticePhase _phase = PracticePhase.idle;
  int _currentRound = 1;
  int _remainingMs = 0;
  Timer? _timer;

  // --- 音声 ---
  final AudioPlayer _startPlayer = AudioPlayer();
  static const int _startOffset = 10600; // start02.mp3 のオフセット
  static const String _startSound = 'sounds/start02.mp3';

  // --- スピードラインアニメーション ---
  late AnimationController _speedLineController;
  late AnimationController _pulseController;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _speedLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _startPlayer.dispose();
    _speedLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// 合計時間を計算
  String get _totalTimeDisplay {
    final totalSec = (_sprintSec + _restSec) * _totalRounds;
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    return '${min}分${sec.toString().padLeft(2, '0')}秒';
  }

  /// 残り秒数を表示用に変換
  String _formatRemaining(int ms) {
    final sec = ms / 1000;
    return sec.toStringAsFixed(1);
  }

  // ========================================
  //  スタート・フェーズ制御
  // ========================================

  /// スタートボタン押下
  Future<void> _onStart() async {
    setState(() {
      _phase = PracticePhase.countdown;
      _currentRound = 1;
    });

    final playStart = DateTime.now();
    await _startPlayer.play(AssetSource(_startSound));
    final measureStart =
        playStart.add(const Duration(milliseconds: _startOffset));

    final waitMs =
        measureStart.difference(DateTime.now()).inMilliseconds;
    if (waitMs > 0) {
      await Future.delayed(Duration(milliseconds: waitMs));
    }

    // カウントダウン中にキャンセルされた場合
    if (_phase != PracticePhase.countdown) return;

    _startSprint();
  }

  /// 走りフェーズ開始
  void _startSprint() {
    setState(() {
      _phase = PracticePhase.sprint;
      _remainingMs = _sprintSec * 1000;
    });
    _startCountdownTimer();
  }

  /// 休憩フェーズ開始
  void _startRest() {
    setState(() {
      _phase = PracticePhase.rest;
      _remainingMs = _restSec * 1000;
    });
    _startCountdownTimer();

    // 休憩の最後にスタート音を再生（次のラウンドのカウントダウン）
    if (_currentRound < _totalRounds) {
      final soundDelay = (_restSec * 1000) - _startOffset;
      if (soundDelay > 0) {
        Future.delayed(Duration(milliseconds: soundDelay), () {
          if (_phase == PracticePhase.rest) {
            _startPlayer.play(AssetSource(_startSound));
          }
        });
      }
    }
  }

  /// カウントダウンタイマーを開始
  void _startCountdownTimer() {
    _timer?.cancel();
    final startTime = DateTime.now();
    final initialRemaining = _remainingMs;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final elapsed =
          DateTime.now().difference(startTime).inMilliseconds;
      final remaining = initialRemaining - elapsed;

      if (remaining <= 0) {
        _timer?.cancel();
        if (_phase == PracticePhase.sprint) {
          _startRest();
        } else if (_phase == PracticePhase.rest) {
          if (_currentRound < _totalRounds) {
            setState(() => _currentRound++);
            _startSprint();
          } else {
            _onFinished();
          }
        }
      } else {
        // 残り3秒でパルスアニメーション
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

  /// 完了
  void _onFinished() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _phase = PracticePhase.finished;
      _remainingMs = 0;
    });
  }

  /// 中止
  void _onCancel() {
    _timer?.cancel();
    _startPlayer.stop();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _phase = PracticePhase.idle;
      _currentRound = 1;
      _remainingMs = 0;
    });
  }

  /// リセット
  void _onReset() {
    setState(() {
      _phase = PracticePhase.idle;
      _currentRound = 1;
      _remainingMs = 0;
    });
  }

  // ========================================
  //  全体進捗を計算
  // ========================================

  double get _overallProgress {
    if (_phase == PracticePhase.idle ||
        _phase == PracticePhase.countdown) return 0;
    if (_phase == PracticePhase.finished) return 1;

    final roundMs = (_sprintSec + _restSec) * 1000;
    final totalMs = roundMs * _totalRounds;
    final completedMs = (_currentRound - 1) * roundMs;

    final currentPhaseTotal =
        (_phase == PracticePhase.sprint ? _sprintSec : _restSec) *
            1000;
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
      body: SafeArea(
        child: Column(
          children: [
            // --- 設定エリア ---
            if (!isRunning) _buildSettings(),

            // --- メインエリア ---
            Expanded(child: _buildMainArea()),

            // --- ボタンエリア ---
            _buildButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 設定パネル（待機中のみ表示）
  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('インターバル練習',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _settingControl('走る', _sprintSec, '秒',
                  onMinus: () {
                    if (_sprintSec > 5) setState(() => _sprintSec -= 5);
                  },
                  onPlus: () {
                    if (_sprintSec < 60) setState(() => _sprintSec += 5);
                  }),
              _settingControl('休む', _restSec, '秒',
                  onMinus: () {
                    if (_restSec > 5) setState(() => _restSec -= 5);
                  },
                  onPlus: () {
                    if (_restSec < 120) setState(() => _restSec += 5);
                  }),
              _settingControl('回数', _totalRounds, '回',
                  onMinus: () {
                    if (_totalRounds > 1) setState(() => _totalRounds--);
                  },
                  onPlus: () {
                    if (_totalRounds < 20) setState(() => _totalRounds++);
                  }),
            ],
          ),
          const SizedBox(height: 8),
          Text('合計: $_totalTimeDisplay',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// 設定コントロール（+/- ボタン）
  Widget _settingControl(
    String label, int value, String unit, {
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onMinus,
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 28,
            ),
            Text('$value$unit',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: onPlus,
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 28,
            ),
          ],
        ),
      ],
    );
  }

  /// メインエリア（フェーズ表示 + スピードライン）
  Widget _buildMainArea() {
    if (_phase == PracticePhase.idle) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('設定してスタート！',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // スピードラインアニメーション（走りフェーズのみ）
        if (_phase == PracticePhase.sprint) _buildSpeedLines(),

        // メインコンテンツ
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _phaseGradient,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // フェーズ名
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _remainingMs <= 3000
                      ? 1.0 + _pulseController.value * 0.15
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Text(
                      _phaseText,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _remainingMs <= 3000 &&
                                _phase != PracticePhase.finished
                            ? Colors.red
                            : Colors.white,
                        shadows: const [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black54,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // カウントダウン
              if (_phase == PracticePhase.sprint ||
                  _phase == PracticePhase.rest)
                Text(
                  _formatRemaining(_remainingMs),
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: _remainingMs <= 3000
                        ? Colors.red
                        : Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),

              if (_phase == PracticePhase.finished)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('おつかれさま！',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )),
                ),

              const SizedBox(height: 16),

              // ラウンド表示
              if (_phase != PracticePhase.finished)
                Text(
                  'ラウンド $_currentRound / $_totalRounds',
                  style: const TextStyle(
                      fontSize: 20, color: Colors.white70),
                ),

              const SizedBox(height: 24),

              // 進捗バー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _overallProgress,
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _phase == PracticePhase.finished
                          ? Colors.amber
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// スピードラインアニメーション
  Widget _buildSpeedLines() {
    return AnimatedBuilder(
      animation: _speedLineController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SpeedLinePainter(
            progress: _speedLineController.value,
            random: _random,
          ),
        );
      },
    );
  }

  /// フェーズ別のグラデーション色
  List<Color> get _phaseGradient {
    switch (_phase) {
      case PracticePhase.countdown:
        return [Colors.grey[800]!, Colors.grey[900]!];
      case PracticePhase.sprint:
        return _remainingMs <= 3000
            ? [Colors.red[700]!, Colors.red[900]!]
            : [Colors.green[600]!, Colors.green[900]!];
      case PracticePhase.rest:
        return _remainingMs <= 3000
            ? [Colors.orange[700]!, Colors.orange[900]!]
            : [Colors.blue[600]!, Colors.blue[900]!];
      case PracticePhase.finished:
        return [Colors.amber[600]!, Colors.amber[900]!];
      default:
        return [Colors.grey[200]!, Colors.grey[300]!];
    }
  }

  /// フェーズ別のテキスト
  String get _phaseText {
    switch (_phase) {
      case PracticePhase.countdown:
        return '準備...';
      case PracticePhase.sprint:
        return '走れ!';
      case PracticePhase.rest:
        return '休憩';
      case PracticePhase.finished:
        return '完了!';
      default:
        return '';
    }
  }

  /// ボタンエリア
  Widget _buildButtons() {
    switch (_phase) {
      case PracticePhase.idle:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('スタート',
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      case PracticePhase.countdown:
      case PracticePhase.sprint:
      case PracticePhase.rest:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('中止',
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      case PracticePhase.finished:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('リセット',
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        );
    }
  }
}

// ========================================
//  スピードラインのカスタムペインター
// ========================================

class _SpeedLinePainter extends CustomPainter {
  final double progress;
  final Random random;

  _SpeedLinePainter({required this.progress, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 集中線（中心から外に向かう線）
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < 30; i++) {
      // 擬似ランダム（seedを固定して安定させる）
      final angle = (i * 12.0 + progress * 360) * pi / 180;
      final innerR = 60.0 + (i % 5) * 20;
      final outerR = size.width * 0.8 + (i % 3) * 40;
      final opacity = 0.1 + (i % 4) * 0.08;

      paint.color = Colors.white.withAlpha((opacity * 255).toInt());

      final x1 = centerX + cos(angle) * innerR;
      final y1 = centerY + sin(angle) * innerR;
      final x2 = centerX + cos(angle) * outerR;
      final y2 = centerY + sin(angle) * outerR;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // 流れる光の粒子
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 15; i++) {
      final angle = (i * 24.0 + progress * 720) * pi / 180;
      final dist = 80.0 + ((i * 47 + (progress * 200).toInt()) % 300);
      final x = centerX + cos(angle) * dist;
      final y = centerY + sin(angle) * dist;
      final radius = 1.5 + (i % 3) * 1.0;

      paint.color = Colors.white.withAlpha(80 + (i % 4) * 30);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
