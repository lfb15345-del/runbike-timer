// App Store 用スクリーンショットを自動で作る道具（実機なしで、アプリの実際の画面を描いて保存する）
//
// 実行: flutter test tool/screenshots_test.dart   （check.bat からも実行される）
// 出力: ランバイク/appstore_screenshots/v1.1.0/ に 1242x2688 のPNG（iPhone 6.5インチ用）
//
// 仕組み: テスト用の仮想画面に本物の画面ウィジェットを表示して画像にする。
// データベース・音・カメラは実機がないと動かないので、見本データを返す「代役」に差し替えている。
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runbike_app/screens/analysis_screen.dart';
import 'package:runbike_app/screens/course_screen.dart';
import 'package:runbike_app/screens/measure_screen.dart';
import 'package:runbike_app/screens/practice_screen.dart';
import 'package:runbike_app/services/app_settings.dart';
import 'package:runbike_app/services/database_service.dart';
import 'package:runbike_app/theme.dart';

final GlobalKey _shotKey = GlobalKey();
const String _outDir = '../appstore_screenshots/v1.1.0';

/// フォントを読み込む（読み込まないとテスト画面では文字が四角になる）
Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var count = 0;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    count++;
  }
  if (count > 0) await loader.load();
}

/// データベースの代役: 見本データを返す
Future<Object?> _fakeDatabase(MethodCall call) async {
  switch (call.method) {
    case 'getDatabasesPath':
      return Directory.systemTemp.path;
    case 'openDatabase':
      return <String, Object?>{'id': 1};
    case 'query':
      final sql = (call.arguments as Map)['sql'] as String;
      return _fakeQuery(sql);
    case 'insert':
    case 'update':
      return 1;
    default:
      return null;
  }
}

Map<String, Object?> _table(List<String> columns, List<List<Object?>> rows) =>
    <String, Object?>{'columns': columns, 'rows': rows};

Map<String, Object?> _fakeQuery(String sql) {
  if (sql.contains('user_version')) {
    return _table(['user_version'], [
      [2]
    ]);
  }
  if (sql.contains('MIN(rr.time_ms)')) {
    return _table(['best'], [
      [12310]
    ]);
  }
  if (sql.contains('MAX(rr.max_speed_kmh)')) {
    return _table(['best'], [
      [18.4]
    ]);
  }
  if (sql.contains('MAX(rr.avg_speed_kmh)')) {
    return _table(['best'], [
      [14.2]
    ]);
  }
  if (sql.contains('rr.*')) {
    const columns = [
      'id', 'run_id', 'child_id', 'time_ms', 'note',
      'max_speed_kmh', 'avg_speed_kmh',
    ];
    return _table(columns, [
      [1, 1, 1, 13120, null, null, null],
      [2, 2, 1, 12840, null, 17.6, 13.8],
      [3, 3, 1, 12480, null, 18.4, 14.2],
      [4, 4, 1, 12910, null, null, null],
      [5, 5, 1, 12650, null, 18.1, 14.0],
    ]);
  }
  if (sql.contains('FROM child')) {
    return _table(['id', 'name', 'created_at'], [
      [1, 'ゆうた', '2026-04-01T09:00:00'],
    ]);
  }
  if (sql.contains('FROM course') && sql.contains('DESC')) {
    const columns = [
      'id', 'date', 'name', 'length_m', 'first_straight_m', 'curve_count',
      'surface', 'weather', 'note', 'created_at',
    ];
    return _table(columns, [
      [2, '2026-11-08', '中央公園コース', 120, 25, 4, 'アスファルト', '晴れ', '', ''],
      [1, '2026-11-01', '河川敷コース', 90, 20, 2, '芝生', 'くもり', '', ''],
    ]);
  }
  return _table(['id'], []);
}

/// 画面を「アプリの外枠（下タブつき）」に入れて表示する
Widget _frame(Widget screen, int tabIndex) {
  return RepaintBoundary(
    key: _shotKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: screen,
        // main.dart の下タブと同じ並び
        bottomNavigationBar: NavigationBar(
          selectedIndex: tabIndex,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: '計測'),
            NavigationDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt),
                label: '練習'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: '解析・共有'),
            NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(Icons.flag),
                label: 'コース設定'),
            NavigationDestination(
                icon: Icon(Icons.sports, color: AppTheme.goRed),
                label: 'ホイッスル'),
          ],
        ),
      ),
    ),
  );
}

/// iPhone 6.5インチ相当の画面サイズにする（上下の余白 = ノッチとホームバーの分）
void _useIphoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1242, 2688);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
  tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
  addTearDown(tester.view.reset);
}

/// いまの画面をPNGで保存する
Future<void> _shoot(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_outDir/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

/// データの読み込みや切り替えアニメーションが落ち着くまで少し進める
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 画面を片付ける（動いているタイマーを止める）
Future<void> _cleanUp(WidgetTester tester) async {
  MeasureScreen.isRunning = false;
  PracticeScreen.isRunning = false;
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // --- フォント ---
    await _loadFont('Noto Sans JP',
        ['assets/fonts/NotoSansJP-VariableFont_wght.ttf']);
    await _loadFont('Barlow Condensed', [
      'assets/fonts/BarlowCondensed-SemiBold.ttf',
      'assets/fonts/BarlowCondensed-Bold.ttf',
      'assets/fonts/BarlowCondensed-BoldItalic.ttf',
      'assets/fonts/BarlowCondensed-ExtraBoldItalic.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
    await _loadFont('MaterialIcons', [
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);

    // --- 実機がないと動かない部品の代役 ---
    final messenger = binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.tekartik.sqflite'), _fakeDatabase);
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path);
    // それ以外（音・カメラなど）は「何もせず成功」と返す
    messenger.allMessagesHandler = (channel, handler, message) {
      if (handler != null) return handler(message);
      return Future<ByteData?>.value(
          const StandardMethodCodec().encodeSuccessEnvelope(null));
    };

    await DatabaseService.init();
  });

  testWidgets('01 計測（待機中）', (tester) async {
    _useIphoneSize(tester);
    AppSettings.currentTab.value = 0;
    await tester.pumpWidget(_frame(const MeasureScreen(), 0));
    await _settle(tester);
    await _shoot(tester, '01_measure');
    await _cleanUp(tester);
  });

  testWidgets('02 計測中（GO）', (tester) async {
    _useIphoneSize(tester);
    AppSettings.currentTab.value = 0;
    await tester.pumpWidget(_frame(const MeasureScreen(), 0));
    await _settle(tester);
    // サイレントを選ぶとカウントダウンなしで即計測が始まる
    await tester.tap(find.text('サイレント'));
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pump();
    // 本物の時間を7秒ちょっと進めて、タイムらしい数字にする
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 7310)));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, '02_measure_go');
    await _cleanUp(tester);
  });

  testWidgets('03 練習（設定）', (tester) async {
    _useIphoneSize(tester);
    AppSettings.currentTab.value = 1;
    await tester.pumpWidget(_frame(const PracticeScreen(), 1));
    await _settle(tester);
    await _shoot(tester, '03_practice');
    await _cleanUp(tester);
  });

  testWidgets('04 練習中（GO）', (tester) async {
    _useIphoneSize(tester);
    AppSettings.currentTab.value = 1;
    await tester.pumpWidget(_frame(const PracticeScreen(), 1));
    await _settle(tester);
    await tester.tap(find.text('無音'));
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pump();
    // スタート音のカウントダウン（約10.6秒）を早送り → GO!
    await tester.pump(const Duration(seconds: 11));
    await tester.pump(const Duration(milliseconds: 30));
    // 本物の時間を進めて、残り12秒台にする
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 7500)));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, '04_practice_go');
    await _cleanUp(tester);
  });

  testWidgets('05 解析・共有', (tester) async {
    _useIphoneSize(tester);
    AppSettings.currentTab.value = 2;
    await tester.pumpWidget(_frame(const AnalysisScreen(), 2));
    await _settle(tester);
    await _shoot(tester, '05_analysis');
    await _cleanUp(tester);
  });

  testWidgets('06 コース設定', (tester) async {
    _useIphoneSize(tester);
    AppSettings.currentTab.value = 3;
    await tester.pumpWidget(_frame(const CourseScreen(), 3));
    await _settle(tester);
    await _shoot(tester, '06_course');
    await _cleanUp(tester);
  });
}
