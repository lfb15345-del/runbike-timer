import 'package:flutter/material.dart';
import 'screens/measure_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/course_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const RunbikeApp());
}

/// ランバイク計測アプリのメインクラス
class RunbikeApp extends StatelessWidget {
  const RunbikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ランバイクタイマー',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// 4タブのメイン画面
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _screens = const [
    MeasureScreen(),
    PracticeScreen(),
    AnalysisScreen(),
    CourseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack でタブ切替してもタイマーが消えない
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer),
            selectedIcon: Icon(Icons.timer, color: Colors.green),
            label: '計測',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center, color: Colors.green),
            label: '練習',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Colors.green),
            label: '解析・共有',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Colors.green),
            label: 'コース設定',
          ),
        ],
      ),
    );
  }
}
