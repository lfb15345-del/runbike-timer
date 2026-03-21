import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

/// 解析・共有タブ
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadChildren();
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
      } else if (_selectedChildId == null) {
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
    return '${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
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
              '${_formatTime(timeMs)}秒 のスピード記録',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '最高速度 (km/h)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed, color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: avgController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '平均速度 (km/h)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_up, color: Colors.blue),
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
                    child: const Text('キャンセル'),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('保存'),
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
    buffer.writeln('$_selectedChildName の今日の記録');
    buffer.writeln('');

    for (int i = 0; i < _todayResults.length; i++) {
      final r = _todayResults[i];
      final timeMs = r['time_ms'] as int;
      final maxSpd = r['max_speed_kmh'] as double?;
      final avgSpd = r['avg_speed_kmh'] as double?;
      final isBest = timeMs == _todayBest;
      buffer.write('${i + 1}本目: ${_formatTime(timeMs)}秒');
      if (maxSpd != null) buffer.write(' 最高${maxSpd.toStringAsFixed(1)}km/h');
      if (avgSpd != null) buffer.write(' 平均${avgSpd.toStringAsFixed(1)}km/h');
      if (isBest && _todayResults.length > 1) buffer.write(' ★ベスト');
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('結果をコピーしました！'), duration: Duration(seconds: 2)),
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
              const Text(
                '解析・共有',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 子ども選択（複数いる場合のみ表示）
              if (_children.length > 1) ...[
                const Text('子どもを選択:', style: TextStyle(fontSize: 16)),
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
                        _statColumn('今日の本数', '${_todayResults.length}'),
                        _statColumn(
                          '今日のベスト',
                          _todayBest != null ? '${_formatTime(_todayBest!)}秒' : '-',
                        ),
                        _statColumn(
                          '歴代ベスト',
                          _allTimeBest != null ? '${_formatTime(_allTimeBest!)}秒' : '-',
                        ),
                      ],
                    ),
                  ),
                ),

                // スピード記録カード（データがある場合のみ）
                if (_bestMaxSpeed != null || _bestAvgSpeed != null)
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.speed, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text('スピード記録',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statColumn(
                                '歴代 最高速度',
                                _bestMaxSpeed != null
                                    ? '${_bestMaxSpeed!.toStringAsFixed(1)} km/h'
                                    : '-',
                              ),
                              _statColumn(
                                '歴代 平均速度ベスト',
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

                const Row(
                  children: [
                    Text('今日の走行一覧',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Text('タップで速度入力 / スワイプで削除',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: _todayResults.isEmpty
                      ? const Center(child: Text('まだ今日の記録がありません'))
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
                                    title: const Text('記録を削除'),
                                    content: Text('${_formatTime(timeMs)}秒 の記録を削除しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('削除',
                                            style: TextStyle(color: Colors.red)),
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
                                      isBest ? Colors.amber : Colors.grey[300],
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(
                                  '${_formatTime(timeMs)} 秒',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        isBest ? FontWeight.bold : FontWeight.normal,
                                    color: isBest ? Colors.amber[800] : null,
                                  ),
                                ),
                                subtitle: hasSpeed
                                    ? Text(
                                        [
                                          if (maxSpd != null) '最高 ${maxSpd.toStringAsFixed(1)}km/h',
                                          if (avgSpd != null) '平均 ${avgSpd.toStringAsFixed(1)}km/h',
                                        ].join('  '),
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 13,
                                        ),
                                      )
                                    : null,
                                trailing: isBest
                                    ? const Icon(Icons.star, color: Colors.amber)
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
                    label: const Text('今日の記録をシェア'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],

              if (_selectedChildId == null && _children.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('計測タブで子どもを登録してください',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
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
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
