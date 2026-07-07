// アプリのUIが組み立てられることを確認する最小限のテスト
// （データベースが必要な画面はテスト環境では動かないため、起動画面で確認）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runbike_app/main.dart';
import 'package:runbike_app/theme.dart';

void main() {
  testWidgets('起動画面（音声解禁画面）が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const WebAudioUnlockScreen(),
    ));

    expect(find.text('ランバイクタイマー'), findsOneWidget);
    expect(find.text('タップして開始'), findsOneWidget);
  });
}
