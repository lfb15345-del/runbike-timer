import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

/// 解析・共有タブ
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  /// このタブが開かれたときに最新データを読み直すための合図。
  /// main.dart のタブ切替処理が値を増やすと、画面がデータを再読み込みする
  /// （従来は起動時の1回しか読み込まれず、計測後のタイムが反映されなかった）
  static final ValueNotifier<int> refreshTick = ValueNotifier<int>(0);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<Map<String, dynamic>> _children = [];
  int? _selectedChildId;
  String _selectedChildName = '';

  List<Map<String, dynamic>> _todayResults = [];
  int? _todayBest;
  int? _allTimeBest;
  double? _bestMaxSpeed;
  double? _bestAvgSpeed;

  /// 画面の文字（端末の言語に合わせた翻訳）
  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _loadChildren();
    // タブが開かれるたびに最新データを読み直す
    AnalysisScreen.refreshTick.addListener(_onRefreshRequested);
  }

  @override
  void dispose() {
    AnalysisScreen.refreshTick.removeListener(_onRefreshRequested);
    super.dispose();
  }

  void _onRefreshRequested() {
    if (mounted) _loadChildren();
  }

  Future<void> _loadChildren() async {
    final children = await DatabaseService.getChildren();
    setState(() {
      _children = children;
    });

    // 計測タブで選んだ子どもを優先、なければ最初の子を自動選択
    if (children.isNotEmpty) {
      final sharedId = DatabaseService.selectedChildId;
      final sharedName = DatabaseService.selectedChildName;
      if (sharedId != null && children.any((c) => c['id'] == sharedId)) {
        await _selectChild(sharedId, sharedName!);
      } else if (_selectedChildId != null &&
          children.any((c) => c['id'] == _selectedChildId)) {
        // すでに選択中の子がいれば、その子のデータを読み直す（再読み込み対応）
        await _selectChild(_selectedChildId!, _selectedChildName);
      } else {
        await _selectChild(
          children.first['id'] as int,
          children.first['name'] as String,
        );
      }
    }
  }

  /// 子どもを選択してデータを読み込む
  Future<void> _selectChild(int childId, String childName) async {
    final results = await DatabaseService.getTodayResults(childId);
    final allTimeBest = await DatabaseService.getAllTimeBest(childId);
    final bestMaxSpeed = await DatabaseService.getAllTimeBestMaxSpeed(childId);
    final bestAvgSpeed = await DatabaseService.getAllTimeBestAvgSpeed(childId);

    int? todayBest;
    if (results.isNotEmpty) {
      todayBest = results
          .map((r) => r['time_ms'] as int)
          .reduce((a, b) => a < b ? a : b);
    }

    setState(() {
      _selectedChildId = childId;
      _selectedChildName = childName;
      _todayResults = results;
      _todayBest = todayBest;
      _allTimeBest = allTimeBest;
      _bestMaxSpeed = bestMaxSpeed;
      _bestAvgSpeed = bestAvgSpeed;
    });
  }

  /// タイムを見やすい文字列に変換
  String _formatTime(int ms) {
    final seconds = ms ~/ 1000;
    final millis = ms % 1000;
    // 表示は2桁（1/100秒）まで。記録自体はミリ秒精度で保存している
    final centis = millis ~/ 10;
    return '${seconds.toString().padLeft(2, '0')}.${centis.toString().padLeft(2, '0')}';
  }

  /// 速度入力ダイアログ
  void _showSpeedInputDialog(Map<String, dynamic> result) {
    final resultId = result['id'] as int;
    final timeMs = result['time_ms'] as int;
    final currentMax = result['max_speed_kmh'] as double?;
    final currentAvg = result['avg_speed_kmh'] as double?;

    final maxController = TextEditingController(
      text: currentMax != null ? currentMax.toString() : '',
    );
    final avgController = TextEditingController(
      text: currentAvg != null ? currentAvg.toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.speedRecordFor(_formatTime(timeMs)),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.maxSpeedKmh,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.speed, color: AppTheme.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: avgController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.avgSpeedKmh,
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          const Icon(Icons.trending_up, color: AppTheme.ink),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final maxSpeed = double.tryParse(maxController.text);
                      final avgSpeed = double.tryParse(avgController.text);
                      await DatabaseService.updateRunResultSpeed(
                        runResultId: resultId,
                        maxSpeedKmh: maxSpeed,
                        avgSpeedKmh: avgSpeed,
                      );
                      if (mounted) Navigator.pop(context);
                      // データを再読み込み
                      await _selectChild(_selectedChildId!, _selectedChildName);
                    },
                    child: Text(l.save),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// シェアテキストを作成（今日の記録一覧 + 速度）
  Future<void> _shareResults() async {
    if (_todayResults.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln(l.shareTitle(_selectedChildName));
    buffer.writeln('');

    for (int i = 0; i < _todayResults.length; i++) {
      final r = _todayResults[i];
      final timeMs = r['time_ms'] as int;
      final maxSpd = r['max_speed_kmh'] as double?;
      final avgSpd = r['avg_speed_kmh'] as double?;
      final isBest = timeMs == _todayBest;
      buffer.write(l.shareLine(i + 1, _formatTime(timeMs)));
      if (maxSpd != null) {
        buffer.write(' ${l.topSpeedValue(maxSpd.toStringAsFixed(1))}');
      }
      if (avgSpd != null) {
        buffer.write(' ${l.avgSpeedValue(avgSpd.toStringAsFixed(1))}');
      }
      if (isBest && _todayResults.length > 1) buffer.write(' ${l.shareBest}');
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.resultsCopied),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.tabAnalysis,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 子ども選択（複数いる場合のみ表示）
              if (_children.length > 1) ...[
                Text(l.selectChild, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _children.map((child) {
                    final isSelected = child['id'] == _selectedChildId;
                    return ChoiceChip(
                      label: Text(child['name'] as String),
                      selected: isSelected,
                      onSelected: (_) => _selectChild(
                        child['id'] as int,
                        child['name'] as String,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // 選択済みの場合、データ表示
              if (_selectedChildId != null) ...[
                // 名前表示（子ども1人の場合）
                if (_children.length <= 1)
                  Text(
                    _selectedChildName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                // タイムサマリーカード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statColumn(l.todayCount, '${_todayResults.length}'),
                        _statColumn(
                          l.todayBest,
                          _todayBest != null
                              ? l.timeSecShort(_formatTime(_todayBest!))
                              : '-',
                        ),
                        _statColumn(
                          l.allTimeBest,
                          _allTimeBest != null
                              ? l.timeSecShort(_formatTime(_allTimeBest!))
                              : '-',
                        ),
                      ],
                    ),
                  ),
                ),

                // スピード記録カード（データがある場合のみ）
                if (_bestMaxSpeed != null || _bestAvgSpeed != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speed,
                                  color: AppTheme.ink, size: 20),
                              const SizedBox(width: 8),
                              Text(l.speedRecords,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statColumn(
                                l.bestTopSpeed,
                                _bestMaxSpeed != null
                                    ? '${_bestMaxSpeed!.toStringAsFixed(1)} km/h'
                                    : '-',
                              ),
                              _statColumn(
                                l.bestAvgSpeed,
                                _bestAvgSpeed != null
                                    ? '${_bestAvgSpeed!.toStringAsFixed(1)} km/h'
                                    : '-',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Text(l.todayRides,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(l.tapSwipeHint,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: _todayResults.isEmpty
                      ? Center(child: Text(l.noRidesToday))
                      : ListView.builder(
                          itemCount: _todayResults.length,
                          itemBuilder: (context, index) {
                            final result = _todayResults[index];
                            final timeMs = result['time_ms'] as int;
                            final resultId = result['id'] as int;
                            final isBest = timeMs == _todayBest;
                            final maxSpd = result['max_speed_kmh'] as double?;
                            final avgSpd = result['avg_speed_kmh'] as double?;
                            final hasSpeed = maxSpd != null || avgSpd != null;

                            return Dismissible(
                              key: ValueKey(resultId),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l.deleteRideTitle),
                                    content: Text(
                                        l.deleteRideMessage(_formatTime(timeMs))),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(l.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(l.delete,
                                            style: const TextStyle(
                                                color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ) ?? false;
                              },
                              onDismissed: (_) async {
                                await DatabaseService.deleteRunResult(resultId);
                                await _selectChild(_selectedChildId!, _selectedChildName);
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      isBest ? AppTheme.volt : AppTheme.line,
                                  child: Text('${index + 1}',
                                      style: AppTheme.timerStyle(
                                          fontSize: 20, color: AppTheme.ink)),
                                ),
                                title: Text(
                                  l.timeSec(_formatTime(timeMs)),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        isBest ? FontWeight.bold : FontWeight.normal,
                                    color: isBest ? AppTheme.deepGreen : null,
                                  ),
                                ),
                                subtitle: hasSpeed
                                    ? Text(
                                        [
                                          if (maxSpd != null)
                                            l.topSpeedValue(
                                                maxSpd.toStringAsFixed(1)),
                                          if (avgSpd != null)
                                            l.avgSpeedValue(
                                                avgSpd.toStringAsFixed(1)),
                                        ].join('  '),
                                        style: TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 13,
                                        ),
                                      )
                                    : null,
                                trailing: isBest
                                    ? const Icon(Icons.star, color: AppTheme.deepGreen)
                                    : null,
                                onTap: () => _showSpeedInputDialog(result),
                              ),
                            );
                          },
                        ),
                ),

                // シェアボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _todayResults.isNotEmpty ? _shareResults : null,
                    icon: const Icon(Icons.share),
                    label: Text(l.shareToday),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],

              if (_selectedChildId == null && _children.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(l.registerChildInTimer,
                        style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        // 数字は計時用の斜体フォントで表示（日本語部分は端末の日本語フォントで表示される）
        Text(value,
            style: AppTheme.timerStyle(fontSize: 30)),
      ],
    );
  }
}
