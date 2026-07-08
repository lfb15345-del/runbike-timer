import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// ランバイク（バランスバイク）のロゴマーク。
/// アプリアイコンと同じデザイン言語（ペダル・チェーンなしの低いフレーム、
/// 大きめの車輪、アンバーのアクセント）をベクターで描画する。
/// [motion] にアニメーション値(0.0〜1.0)を渡すと、後方のスピードラインが流れる。
class RunbikeMark extends StatelessWidget {
  final double width;
  final double height;
  final Color markColor;
  final Color accentColor;
  final double motion;

  const RunbikeMark({
    super.key,
    required this.width,
    required this.height,
    this.markColor = Colors.white,
    this.accentColor = AppTheme.accentAmber,
    this.motion = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _RunbikePainter(
          markColor: markColor,
          accentColor: accentColor,
          motion: motion,
        ),
      ),
    );
  }
}

class _RunbikePainter extends CustomPainter {
  final Color markColor;
  final Color accentColor;
  final double motion;

  _RunbikePainter({
    required this.markColor,
    required this.accentColor,
    required this.motion,
  });

  // デザイン座標系（アイコン生成スクリプトと同じ設計思想）
  static const _rw = Offset(315, 700); // 後輪中心
  static const _fw = Offset(760, 700); // 前輪中心
  static const _wheelR = 172.0;

  // コンテンツのバウンディングボックス（フィット計算用）
  static const _contentLeft = 60.0;
  static const _contentTop = 270.0;
  static const _contentRight = 960.0;
  static const _contentBottom = 890.0;

  @override
  void paint(Canvas canvas, Size size) {
    const contentW = _contentRight - _contentLeft;
    const contentH = _contentBottom - _contentTop;
    final scale = (size.width / contentW < size.height / contentH)
        ? size.width / contentW
        : size.height / contentH;
    final contentCenter = const Offset(
        (_contentLeft + _contentRight) / 2, (_contentTop + _contentBottom) / 2);
    final canvasCenter = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(canvasCenter.dx, canvasCenter.dy);
    canvas.scale(scale);
    canvas.translate(-contentCenter.dx, -contentCenter.dy);

    _drawMotionLines(canvas);
    _drawWheel(canvas, _rw);
    _drawWheel(canvas, _fw);
    _drawFrame(canvas);
    _drawSeat(canvas);
    _drawHandlebar(canvas);

    canvas.restore();
  }

  void _drawMotionLines(Canvas canvas) {
    // motion（0〜1）で左右にゆるく流れるスピードライン
    final shift = motion * 40;
    final lines = [
      (yy: 430.0, x2: 150.0, length: 100.0, w: 20.0, alpha: 0.28),
      (yy: 490.0, x2: 90.0, length: 150.0, w: 28.0, alpha: 0.4),
      (yy: 555.0, x2: 120.0, length: 118.0, w: 22.0, alpha: 0.3),
      (yy: 615.0, x2: 160.0, length: 82.0, w: 16.0, alpha: 0.2),
    ];
    for (final l in lines) {
      final paint = Paint()
        ..color = markColor.withValues(alpha: l.alpha)
        ..strokeWidth = l.w
        ..strokeCap = StrokeCap.round;
      final x2 = l.x2 - shift;
      final x1 = x2 - l.length;
      canvas.drawLine(Offset(x1, l.yy), Offset(x2, l.yy - 12), paint);
    }
  }

  void _drawWheel(Canvas canvas, Offset center) {
    final tirePaint = Paint()..color = markColor;
    canvas.drawCircle(center, _wheelR, tirePaint);

    final innerR = _wheelR - 46;
    final darkPaint = Paint()..color = AppTheme.brandGradient.last;
    canvas.drawCircle(center, innerR, darkPaint);

    final spokePaint = Paint()
      ..color = markColor.withValues(alpha: 0.43)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (final deg in [0, 30, 60, 90, 120, 150]) {
      final rad = deg * math.pi / 180;
      final dx = (innerR - 16) * math.cos(rad);
      final dy = (innerR - 16) * math.sin(rad);
      canvas.drawLine(center - Offset(dx, dy), center + Offset(dx, dy), spokePaint);
    }

    canvas.drawCircle(center, 26, Paint()..color = accentColor);
  }

  void _drawFrame(Canvas canvas) {
    final path = Path()
      ..moveTo(345, 630)
      ..quadraticBezierTo(400, 590, 455, 565)
      ..quadraticBezierTo(490, 545, 520, 520)
      ..quadraticBezierTo(560, 528, 610, 540)
      ..quadraticBezierTo(670, 565, 720, 605);
    final paint = Paint()
      ..color = markColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  void _drawSeat(Canvas canvas) {
    final postPaint = Paint()
      ..color = markColor
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(465, 570), const Offset(365, 430), postPaint);

    final saddlePaint = Paint()
      ..color = markColor
      ..strokeWidth = 46
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(293, 436), const Offset(435, 412), saddlePaint);
  }

  void _drawHandlebar(Canvas canvas) {
    final postPaint = Paint()
      ..color = markColor
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(640, 545), const Offset(700, 360), postPaint);

    final barPaint = Paint()
      ..color = markColor
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;
    const gripA = Offset(636, 410);
    const gripB = Offset(760, 318);
    canvas.drawLine(gripA, gripB, barPaint);

    final gripPaint = Paint()..color = accentColor;
    canvas.drawCircle(gripA, 24, gripPaint);
    canvas.drawCircle(gripB, 24, gripPaint);
  }

  @override
  bool shouldRepaint(covariant _RunbikePainter oldDelegate) =>
      oldDelegate.motion != motion ||
      oldDelegate.markColor != markColor ||
      oldDelegate.accentColor != accentColor;
}
