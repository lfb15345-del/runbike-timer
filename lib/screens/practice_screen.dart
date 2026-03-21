import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final AudioPlayer _bellPlayer = AudioPlayer();
  static const int _startOffset = 10600;
  static const String _startSound = 'sounds/start02.mp3';
  static const String _bellSound = 'sounds/bell.wav';

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _startPlayer.dispose();
    _bellPlayer.dispose();
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

  Future<void> _onStart() async {
    setState(() {
      _phase = PracticePhase.countdown;
      _currentRound = 1;
    });

    final playStart = DateTime.now();
    await _startPlayer.play(AssetSource(_startSound));
    final measureStart =
        playStart.add(const Duration(milliseconds: _startOffset));

    final waitMs = measureStart.difference(DateTime.now()).inMilliseconds;
    if (waitMs > 0) {
      await Future.delayed(Duration(milliseconds: waitMs));
    }
    if (_phase != PracticePhase.countdown) return;
    _startSprint();
  }

  void _startSprint() {
    // バイブレーション
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = PracticePhase.sprint;
      _remainingMs = _sprintSec * 1000;
    });
    _startCountdownTimer();
  }

  void _startRest() {
    // カンカン音を鳴らす
    _bellPlayer.play(AssetSource(_bellSound));
    HapticFeedback.mediumImpact();

    setState(() {
      _phase = PracticePhase.rest;
      _remainingMs = _restSec * 1000;
    });
    _startCountdownTimer();

    // 休憩の最後にスタート音を再生
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
    _bellPlayer.play(AssetSource(_bellSound));
    HapticFeedback.heavyImpact();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _phase = PracticePhase.finished;
      _remainingMs = 0;
    });
  }

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

  void _onReset() {
    setState(() {
      _phase = PracticePhase.idle;
      _currentRound = 1;
      _remainingMs = 0;
    });
  }

  double get _overallProgress {
    if (_phase == PracticePhase.idle ||
        _phase == PracticePhase.countdown) return 0;
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
      body: SafeArea(
        child: Column(
          children: [
            if (!isRunning) _buildSettings(),
            Expanded(child: _buildMainArea()),
            _buildButtons(),
            const SizedBox(height: 16),
          ],
        ),
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
          const SizedBox(height: 4),
          Text('合計 $_totalTimeDisplay',
              style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        ],
      ),
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
                  Text(
                    _formatRemaining(_remainingMs),
                    style: TextStyle(
                      fontSize: 90,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: _remainingMs <= 3000
                          ? Colors.yellow
                          : Colors.white,
                      shadows: const [
                        Shadow(blurRadius: 16, color: Colors.black54,
                            offset: Offset(2, 3)),
                      ],
                    ),
                  ),

                if (_phase == PracticePhase.finished)
                  const Text('FINISH!!',
                      style: TextStyle(fontSize: 56,
                          fontWeight: FontWeight.w900,
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
                          fontSize: 18, color: Colors.white,
                          fontWeight: FontWeight.w600,
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
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
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
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900,
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
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800,
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('START',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      letterSpacing: 4)),
            ),
          ),
        );
      case PracticePhase.countdown:
      case PracticePhase.sprint:
      case PracticePhase.rest:
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      letterSpacing: 4)),
            ),
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
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('RESET',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      letterSpacing: 4)),
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
