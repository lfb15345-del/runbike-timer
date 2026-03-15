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
  }

  /// 子どもを選択してデータを読み込む
  Future<void> _selectChild(int childId, String childName) async {
    final results = await DatabaseService.getTodayResults(childId);
    final allTimeBest = await DatabaseService.getAllTimeBest(childId);

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
    });
  }

  /// タイムを見やすい文字列に変換
  String _formatTime(int ms) {
    final seconds = ms ~/ 1000;
    final millis = ms % 1000;
    return '${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  /// シェアテキストを作成して共有
  Future<void> _shareResults() async {
    if (_todayResults.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('--- $_selectedChildName の練習結果！ ---');
    buffer.writeln('');

    for (int i = 0; i < _todayResults.length; i++) {
      final timeMs = _todayResults[i]['time_ms'] as int;
      final isBest = timeMs == _todayBest;
      buffer.write('${i + 1}本目: ${_formatTime(timeMs)}秒');
      if (isBest) buffer.write(' (本日ベスト!)');
      buffer.writeln();
    }

    buffer.writeln('');
    buffer.writeln('合計 ${_todayResults.length} 本');
    if (_todayBest != null) {
      buffer.writeln('本日ベスト: ${_formatTime(_todayBest!)}秒');
    }
    if (_allTimeBest != null) {
      buffer.writeln('歴代ベスト: ${_formatTime(_allTimeBest!)}秒');
    }

    // Web版ではクリップボードにコピー（スマホ版では share_plus を使う）
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('結果をクリップボードにコピーしました！'), duration: Duration(seconds: 2)),
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

              // 子ども選択
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

              const SizedBox(height: 24),

              // 選択済みの場合、データ表示
              if (_selectedChildId != null) ...[
                // サマリーカード
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

                const SizedBox(height: 16),

                const Row(
                  children: [
                    Text('今日の走行一覧', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Text('← スワイプで削除', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                        child: const Text('削除', style: TextStyle(color: Colors.red)),
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
                                  backgroundColor: isBest ? Colors.amber : Colors.grey[300],
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(
                                  '${_formatTime(timeMs)} 秒',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                                    color: isBest ? Colors.amber[800] : null,
                                  ),
                                ),
                                trailing: isBest
                                    ? const Icon(Icons.star, color: Colors.amber)
                                    : null,
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
                    label: const Text('この子の結果をシェア'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],

              if (_selectedChildId == null)
                const Expanded(
                  child: Center(
                    child: Text('上のボタンから子どもを選んでください',
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
