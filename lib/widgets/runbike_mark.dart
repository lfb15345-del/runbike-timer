import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// ランバイクタイマーのロゴマーク（アプリアイコンと同じ形をベクターで描く）。
/// ・[bodyColor] の部分 = 車体（後輪・フレーム・サドル）
/// ・[accentColor] の部分 = 前輪 + フォーク + ハンドル。ここだけ見るとストップウォッチの形
/// ※ 形の数値は tool/generate_icons.py と同じ。変えるときは両方直すこと
class RunbikeMark extends StatelessWidget {
  /// 横幅（高さは形に合わせて自動で決まる）
  final double width;
  final Color bodyColor;
  final Color accentColor;

  const RunbikeMark({
    super.key,
    required this.width,
    this.bodyColor = AppTheme.paper,
    this.accentColor = AppTheme.volt,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * _RunbikePainter.aspect,
      child: CustomPaint(
        painter: _RunbikePainter(
          bodyColor: bodyColor,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _RunbikePainter extends CustomPainter {
  final Color bodyColor;
  final Color accentColor;

  _RunbikePainter({required this.bodyColor, required this.accentColor});

  // ---- 設計座標（1000x1000。generate_icons.py と同じ値） ----
  static const double _stroke = 56;
  static const double _wheelR = 150;
  static const Offset _rearHub = Offset(275, 645);
  static const Offset _frontHub = Offset(705, 645);
  static const Offset _head = Offset(600, 418);
  static const Offset _stemTop = Offset(565, 341);
  static const Offset _barA = Offset(501, 370);
  static const Offset _barB = Offset(629, 312);
  static const Offset _seatBase = Offset(412, 549);
  static const Offset _seatTop = Offset(388, 398);
  static const Offset _saddleA = Offset(316, 398);
  static const Offset _saddleB = Offset(422, 398);

  // 絵柄の外枠（線の太さ込み）
  static const double _left = 97;
  static const double _top = 284;
  static const double _contentW = 786;
  static const double _contentH = 539;

  /// 高さ ÷ 横幅
  static const double aspect = _contentH / _contentW;

  @override
  void paint(Canvas canvas, Size size) {
    final scale =
        math.min(size.width / _contentW, size.height / _contentH);

    canvas.save();
    canvas.translate(
      (size.width - _contentW * scale) / 2,
      (size.height - _contentH * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(-_left, -_top);

    final body = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    // 車体（後輪・フレーム・サドル）
    canvas.drawCircle(_rearHub, _wheelR, body);
    canvas.drawLine(_rearHub, _head, body);
    canvas.drawLine(_seatBase, _seatTop, body);
    canvas.drawLine(_saddleA, _saddleB, body);

    // ストップウォッチ部分（前輪・フォーク・ハンドル）
    canvas.drawCircle(_frontHub, _wheelR, accent);
    canvas.drawLine(_frontHub, _stemTop, accent);
    canvas.drawLine(_barA, _barB, accent);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RunbikePainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.accentColor != accentColor;
}
