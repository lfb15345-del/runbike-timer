import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/measure_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/course_screen.dart';
import 'services/database_service.dart';
import 'services/web_audio_service.dart';

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
      // Web版は音声解禁画面を最初に表示
      home: kIsWeb ? const WebAudioUnlockScreen() : const HomePage(),
    );
  }
}

/// Web版のみ: 最初にタップさせて音声を解禁する画面
class WebAudioUnlockScreen extends StatelessWidget {
  const WebAudioUnlockScreen({super.key});

  Future<void> _unlockAudio(BuildContext context) async {
    // ユーザータップで音声コンテキスト解禁
    // index.html の unlockAudio() が click イベントで自動実行される

    // 全スタート音MP3をWeb Audio APIでプリデコード
    // → 以降の再生はレイテンシーほぼゼロ
    WebAudioService.preloadSound('start01.mp3');
    WebAudioService.preloadSound('start02.mp3');
    WebAudioService.preloadSound('start03.mp3');

    // 少し待ってからホーム画面へ（プリロード開始を確実にする）
    await Future.delayed(const Duration(milliseconds: 500));

    // ホーム画面へ遷移（戻れないように置換）
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => _unlockAudio(context),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1b5e20), Color(0xFF004d40)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bike,
                    size: 100, color: Colors.white.withAlpha(200)),
                const SizedBox(height: 24),
                const Text('ランバイクタイマー',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    )),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: const Text('タップして開始',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      )),
                ),
                const SizedBox(height: 24),
                Text('※ 音声機能を有効にするため\n  最初にタップが必要です',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(150))),
              ],
            ),
          ),
        ),
      ),
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

  /// タイマー実行中はタブ切替をブロック
  void _onTabTapped(int index) {
    // 計測中 or 練習中はタブ切替を防止
    if (MeasureScreen.isRunning || PracticeScreen.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('実行中はタブを切り替えられません'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

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
        onDestinationSelected: _onTabTapped,
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
