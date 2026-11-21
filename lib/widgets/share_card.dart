import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'runbike_mark.dart';

/// 今日の記録を「画像」にしてシェアするための材料
class ShareCardData {
  final String childName;
  final DateTime date;

  /// 今日の走り（古い順、ミリ秒）
  final List<int> timesMs;

  /// 今日のベスト（ミリ秒）
  final int bestMs;

  /// 歴代ベスト（ミリ秒。今日を含む）
  final int? allTimeBestMs;

  /// タイムの表示用（例: 12340 → "12.34"）
  final String Function(int ms) format;

  const ShareCardData({
    required this.childName,
    required this.date,
    required this.timesMs,
    required this.bestMs,
    required this.allTimeBestMs,
    required this.format,
  });

  /// 今日のベストが歴代ベストと同じ = 自己ベスト
  bool get isPersonalBest => allTimeBestMs != null && bestMs <= allTimeBestMs!;
}

/// シェア用の記録カード（Instagram などにそのまま載せられる 4:5 の形）。
/// 画面上の大きさは 360×450。画像にするときは3倍の 1080×1350 で書き出す
class ShareCard extends StatelessWidget {
  static const double cardWidth = 360;
  static const double cardHeight = 450;

  final ShareCardData data;

  const ShareCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = data.date;
    final dateStr =
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    // 走りが多い日は、最後の8本だけ並べる
    final start = data.timesMs.length > 8 ? data.timesMs.length - 8 : 0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      color: AppTheme.ink,
      child: Stack(
        children: [
          // 右上の黄緑の斜めライン（スピード感の飾り）
          Positioned(
            top: -40,
            right: -60,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(width: 200, height: 26, color: AppTheme.volt),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RUNBIKE TIMER',
                    style: AppTheme.labelStyle(
                        fontSize: 13, color: AppTheme.volt)),
                const SizedBox(height: 4),
                Text(dateStr,
                    style: AppTheme.labelStyle(
                        fontSize: 13, color: Colors.white54)),
                const SizedBox(height: 14),
                Text(
                  data.childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.paper,
                      height: 1.2),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(l.todayBest,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white60)),
                    if (data.isPersonalBest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.signal,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(l.cardPersonalBest,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                // 今日のベスト（大きく）
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(data.format(data.bestMs),
                            style: AppTheme.timerStyle(
                                fontSize: 96, color: AppTheme.volt)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l.unitSec,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.volt)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 今日の走り
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = start; i < data.timesMs.length; i++)
                      _runChip(i + 1, data.timesMs[i],
                          data.timesMs[i] == data.bestMs),
                  ],
                ),
                const Spacer(),
                // 本数と歴代ベスト
                Row(
                  children: [
                    _stat(l.todayCount, '${data.timesMs.length}'),
                    const SizedBox(width: 28),
                    _stat(
                        l.allTimeBest,
                        data.allTimeBestMs == null
                            ? '-'
                            : data.format(data.allTimeBestMs!)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: Colors.white12),
                const SizedBox(height: 12),
                // アプリ名（このカードを見た人が探せるように）
                Row(
                  children: [
                    const RunbikeMark(width: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.appTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.paper)),
                          Text(l.cardFooter,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _runChip(int number, int ms, bool isBest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isBest ? AppTheme.volt : Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$number',
              style: AppTheme.labelStyle(
                  fontSize: 11,
                  color: isBest ? AppTheme.ink : Colors.white38)),
          const SizedBox(width: 5),
          Text(data.format(ms),
              style: AppTheme.timerStyle(
                  fontSize: 17,
                  color: isBest ? AppTheme.ink : AppTheme.paper)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTheme.timerStyle(fontSize: 24, color: AppTheme.paper)),
      ],
    );
  }
}

/// 記録カードをプレビューしてから、画像としてシェアする画面（下から出てくる）
Future<void> showShareCardSheet(BuildContext context, ShareCardData data) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ShareCardSheet(data: data),
  );
}

class _ShareCardSheet extends StatefulWidget {
  final ShareCardData data;
  const _ShareCardSheet({required this.data});

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _buttonKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      // カードを 1080×1350 の画像にする
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      // iPad ではシェアの吹き出しを出す位置が必要
      final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin =
          box == null ? null : box.localToGlobal(Offset.zero) & box.size;

      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(bytes, name: 'runbike_timer.png', mimeType: 'image/png')
        ],
        text: l.shareFooter,
        sharePositionOrigin: origin,
      ));
    } catch (e) {
      debugPrint('画像シェアのエラー: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.62;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // プレビュー（画面に収まるように縮めて表示。書き出しは元の大きさ×3）
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: FittedBox(
                fit: BoxFit.contain,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: ShareCard(data: widget.data),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              key: _buttonKey,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _share,
                icon: const Icon(Icons.ios_share),
                label: Text(l.cardShareButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
