import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// カメラプレビューのワイプ表示（ネイティブ版のみ）
/// - 指2本でピンチ → カメラのデジタルズーム
/// - 1本指でドラッグ → ワイプを移動（画面の外へ滑らせて隠すこともできる。
///   端に少しだけ残るので、それを引っ張れば戻せる）
/// - 右下のリサイズハンドル(↘) → ワイプサイズ変更（縦横比はカメラに合わせて固定）
/// - 右上の📷ボタン → 前面/背面カメラ切替
class CameraWipe extends StatefulWidget {
  final CameraController controller;
  final bool isRecording;
  final double zoom; // 現在のズーム倍率（表示・ピンチ基準用）
  final ValueChanged<double> onZoomRequest; // ピンチでズーム変更を要求
  final VoidCallback onSwitchCamera;

  const CameraWipe({
    super.key,
    required this.controller,
    required this.isRecording,
    required this.zoom,
    required this.onZoomRequest,
    required this.onSwitchCamera,
  });

  @override
  State<CameraWipe> createState() => _CameraWipeState();
}

class _CameraWipeState extends State<CameraWipe> {
  // ワイプの位置とサイズ（ドラッグ＆リサイズで変更可能）
  double? _left; // null = 初回表示時に画面右端に配置
  double _top = 8;
  double _width = 140;

  // 画面外に隠したときに端に残す「つまみ」の幅
  static const double _peek = 36;

  // ピンチ検出用: アクティブなタッチポインタを追跡（Listener使用）
  final Map<int, Offset> _pointers = {};
  double _pinchInitDist = 0;
  double _zoomStart = 1.0;

  /// カメラの縦横比に合わせた高さ（アスペクト比固定・映像が歪まない）
  double get _height {
    final ratio = widget.controller.value.aspectRatio;
    // aspectRatio はセンサーの横/縦。縦持ち表示では縦長になる
    return ratio > 0 ? _width * ratio : _width * 1.4;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _left ??= screenSize.width - _width - 8;
    // YouTubeのミニプレイヤー風に、左右は画面の外までスライド可能
    // （_peek 分だけ端に残るので、引っ張れば戻せる）
    final minLeft = -(_width - _peek);
    final maxLeft = screenSize.width - _peek;
    final maxTop =
        (screenSize.height - 80 - _peek).clamp(0.0, double.infinity);
    final left = _left!.clamp(minLeft, maxLeft);
    final top = _top.clamp(0.0, maxTop);

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: _width,
        height: _height,
        // Listener: 生のポインターイベントでピンチ検出（ジェスチャー競合の影響なし）
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _pointers[e.pointer] = e.position;
            if (_pointers.length == 2) {
              final pts = _pointers.values.toList();
              _pinchInitDist = (pts[0] - pts[1]).distance;
              _zoomStart = widget.zoom;
            }
          },
          onPointerMove: (e) {
            if (!_pointers.containsKey(e.pointer)) return;
            _pointers[e.pointer] = e.position;
            if (_pointers.length >= 2 && _pinchInitDist > 5) {
              final pts = _pointers.values.toList();
              final dist = (pts[0] - pts[1]).distance;
              widget.onZoomRequest(_zoomStart * dist / _pinchInitDist);
            }
          },
          onPointerUp: (e) {
            _pointers.remove(e.pointer);
            if (_pointers.length < 2) _pinchInitDist = 0;
          },
          onPointerCancel: (e) {
            _pointers.remove(e.pointer);
            if (_pointers.length < 2) _pinchInitDist = 0;
          },
          // 1本指ドラッグでワイプ移動
          child: GestureDetector(
            onPanUpdate: (details) {
              if (_pointers.length >= 2) return; // ピンチ中は移動しない
              setState(() {
                // 左右は画面外まで許可（つまみ分だけ残る）
                _left = (left + details.delta.dx).clamp(minLeft, maxLeft);
                _top = (top + details.delta.dy).clamp(0.0, maxTop);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isRecording ? Colors.red : Colors.white,
                  width: widget.isRecording ? 3 : 2,
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
                    CameraPreview(widget.controller),

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
                          '${widget.zoom.toStringAsFixed(1)}x',
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
                        onTap: widget.onSwitchCamera,
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
                            // 幅だけ変更し、高さはカメラの縦横比から自動計算（歪み防止）
                            _width = (_width + details.delta.dx)
                                .clamp(80.0, screenSize.width - 16);
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
}
