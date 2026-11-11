import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/measure_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/course_screen.dart';
import 'services/database_service.dart';
import 'services/web_audio_service.dart';
import 'services/sound_service.dart';
import 'services/app_settings.dart';
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

class _WebAudioUnlockScreenState extends State<WebAudioUnlockScreen> {
  bool _isLoading = false;

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
      backgroundColor: AppTheme.ink,
      body: GestureDetector(
        onTap: _unlockAudio,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ロゴマーク（アプリアイコンと同じ形）
                const RunbikeMark(width: 220),
                const SizedBox(height: 28),
                const Text('ランバイクタイマー',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      height: 1.1,
                    )),
                const SizedBox(height: 8),
                Text('RUNBIKE TIMER',
                    style: AppTheme.labelStyle(
                        fontSize: 15, color: AppTheme.volt)),
                const SizedBox(height: 56),

                // ローディング中 or タップ待ち
                if (_isLoading) ...[
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppTheme.volt,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('音声を準備中...',
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.volt,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('タップして開始',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        )),
                  ),
                  const SizedBox(height: 20),
                  const Text('音を鳴らすために、最初に1回タップが必要です',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white54)),
                ],
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

  @override
  void initState() {
    super.initState();
    // タイマーアプリなので、アプリを開いている間は画面をスリープさせない
    // （バックグラウンドに回るとOSが自動で解除するので電池の心配は不要）
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  final _screens = const [
    MeasureScreen(),
    PracticeScreen(),
    AnalysisScreen(),
    CourseScreen(),
  ];

  /// 下タブの一番右はタブではなく「ホイッスルボタン」
  static const int _whistleIndex = 4;

  /// タイマー実行中はタブ切替をブロック
  void _onTabTapped(int index) {
    // ホイッスルは画面を切り替えずに鳴らすだけ（計測中・練習中でも鳴らせる）
    if (index == _whistleIndex) {
      HapticFeedback.mediumImpact();
      SoundService.playRefereeWhistle();
      return;
    }
    // 計測中・練習中でもタブは切り替えられる（タイマーと音は裏でそのまま進む）。
    // ただし「録画しながら」のときだけは止める
    // （タブを離れるとカメラを手放すので、録画が途中で切れてしまうため）
    if ((MeasureScreen.isRunning && MeasureScreen.isRecordingOn) ||
        (PracticeScreen.isRunning && PracticeScreen.isRecordingOn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('録画中はタブを切り替えられません'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    // Web版: 計測タブ以外ではカメラプレビューを非表示
    if (kIsWeb) {
      WebCameraService.setPreviewVisible(index == 0);
    }
    // 解析・共有タブを開いたら最新の記録を読み直す
    if (index == 2) {
      AnalysisScreen.refreshTick.value++;
    }
    AppSettings.currentTab.value = index;
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
            // 稲妻 = ダッシュ練習のイメージ
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: '練習',
          ),
          NavigationDestination(
            // タイム推移のグラフのイメージ
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '解析・共有',
          ),
          NavigationDestination(
            // ゴールの旗 = コースのイメージ
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'コース設定',
          ),
          NavigationDestination(
            // 押すと「ピーーッ」と鳴るだけのボタン（画面は切り替わらない）
            icon: Icon(Icons.sports, color: AppTheme.goRed),
            selectedIcon: Icon(Icons.sports, color: AppTheme.goRed),
            label: 'ホイッスル',
          ),
        ],
      ),
    );
  }
}
