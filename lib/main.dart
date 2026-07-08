import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/measure_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/course_screen.dart';
import 'services/database_service.dart';
import 'services/web_audio_service.dart';
import 'services/web_camera_service.dart';
import 'theme.dart';
import 'widgets/runbike_mark.dart';

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
      locale: const Locale('ja', 'JP'),
      // テーマは theme.dart に一元化（色・ボタン・チップ・タブバー）
      theme: AppTheme.light(),
      // Web版は音声解禁画面を最初に表示
      home: kIsWeb ? const WebAudioUnlockScreen() : const HomePage(),
    );
  }
}

/// Web版のみ: 最初にタップさせて音声を解禁 → MP3プリロード → ホーム画面へ
class WebAudioUnlockScreen extends StatefulWidget {
  const WebAudioUnlockScreen({super.key});

  @override
  State<WebAudioUnlockScreen> createState() => _WebAudioUnlockScreenState();
}

class _WebAudioUnlockScreenState extends State<WebAudioUnlockScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    // ロゴ後方のスピードラインをゆっくりループさせる（レース感の演出）
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  Future<void> _unlockAudio() async {
    if (_isLoading) return; // 二重タップ防止
    setState(() => _isLoading = true);

    // ユーザータップで音声コンテキスト解禁
    // index.html の unlockAudio() が click イベントで自動実行される

    // 全スタート音MP3をWeb Audio APIでプリデコード（完了を待つ）
    await WebAudioService.preloadAllSounds();

    // ホーム画面へ遷移（戻れないように置換）
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandGradient.last,
      body: GestureDetector(
        onTap: _unlockAudio,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.brandGradient,
            ),
          ),
          child: Stack(
            // 非Positioned子（SafeArea配下のColumn）を画面中央に置く
            // （デフォルトのtopLeftのままだと横長画面で左寄りになる）
            alignment: Alignment.center,
            children: [
              // 右下コーナーのチェッカーフラッグ・アクセント（アイコンと共通のブランド言語）
              Positioned(
                right: -24,
                bottom: -24,
                child: Opacity(
                  opacity: 0.5,
                  child: _CheckerAccent(cell: 22, cols: 6, rows: 6),
                ),
              ),
              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _motionController,
                      builder: (context, _) => RunbikeMark(
                        width: 280,
                        height: 190,
                        motion: _motionController.value,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // タイトル + アンダーラインのレースストライプ
                    const Text('ランバイクタイマー',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                          height: 1.1,
                        )),
                    const SizedBox(height: 10),
                    Container(
                      width: 90,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 56),

                    // ローディング中 or タップ待ち
                    if (_isLoading) ...[
                      const SizedBox(
                        width: 44, height: 44,
                        child: CircularProgressIndicator(
                          color: AppTheme.accentAmber,
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('音声を準備中...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            letterSpacing: 2,
                          )),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 44, vertical: 17),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentAmber.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text('タップして開始',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandGradient.last,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// チェッカーフラッグ風のコーナーアクセント（アプリアイコンと共通のブランド言語）
class _CheckerAccent extends StatelessWidget {
  final double cell;
  final int cols;
  final int rows;

  const _CheckerAccent({required this.cell, required this.cols, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cell * cols,
      height: cell * rows,
      child: Wrap(
        children: List.generate(cols * rows, (i) {
          final row = i ~/ cols;
          final col = i % cols;
          final on = (row + col) % 2 == 0;
          return Container(
            width: cell,
            height: cell,
            color: on ? Colors.white : Colors.transparent,
          );
        }),
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
    // Web版: 計測タブ以外ではカメラプレビューを非表示
    if (kIsWeb) {
      WebCameraService.setPreviewVisible(index == 0);
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
        // 選択色はテーマ（theme.dart）で一括管理
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: '計測',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '練習',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: '解析・共有',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'コース設定',
          ),
        ],
      ),
    );
  }
}
