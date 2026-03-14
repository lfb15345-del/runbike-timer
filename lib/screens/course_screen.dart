import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// コース設定タブ
class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final _nameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _straightController = TextEditingController();
  final _noteController = TextEditingController();

  int _curveCount = 0;
  String _surface = 'アスファルト';
  String _weather = '晴れ';

  final _surfaces = ['アスファルト', '芝生', '室内', '砂利', 'その他'];
  final _weathers = ['晴れ', 'くもり', '雨', '風あり'];

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadTodayCourse();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _straightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 今日のコース情報があれば読み込む
  Future<void> _loadTodayCourse() async {
    final course = await DatabaseService.getTodayCourse();
    if (course != null) {
      setState(() {
        _nameController.text = course['name'] ?? '';
        _lengthController.text = course['length_m']?.toString() ?? '';
        _straightController.text = course['first_straight_m']?.toString() ?? '';
        _curveCount = course['curve_count'] ?? 0;
        _surface = course['surface'] ?? 'アスファルト';
        _weather = course['weather'] ?? '晴れ';
        _noteController.text = course['note'] ?? '';
        _saved = true;
      });
    }
  }

  /// 保存
  Future<void> _save() async {
    await DatabaseService.saveCourse(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      lengthM: double.tryParse(_lengthController.text),
      firstStraightM: double.tryParse(_straightController.text),
      curveCount: _curveCount,
      surface: _surface,
      weather: _weather,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    setState(() => _saved = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コース情報を保存しました'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'コース設定',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_saved)
                    const Chip(
                      label: Text('保存済み'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('今日の練習コースの情報を入力できます（任意）',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // コース名
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'コース名',
                  hintText: '例: いつもの公園コース',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // コース全長
              TextField(
                controller: _lengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'コース全長（m）',
                  hintText: '例: 30',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 初回直線
              TextField(
                controller: _straightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '初回直線の長さ（m）',
                  hintText: '例: 10',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // カーブ数
              Row(
                children: [
                  const Text('カーブ数:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _curveCount > 0
                        ? () => setState(() => _curveCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_curveCount',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _curveCount < 10
                        ? () => setState(() => _curveCount++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 路面
              const Text('路面:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _surfaces.map((s) {
                  return ChoiceChip(
                    label: Text(s),
                    selected: _surface == s,
                    onSelected: (_) => setState(() => _surface = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 天気
              const Text('天気:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weathers.map((w) {
                  return ChoiceChip(
                    label: Text(w),
                    selected: _weather == w,
                    onSelected: (_) => setState(() => _weather = w),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // メモ
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                  hintText: '自由にメモを書けます',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('保存する', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
