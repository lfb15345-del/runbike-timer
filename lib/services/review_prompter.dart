import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Store の評価をお願いする係。
///
/// 自己ベストを更新した「うれしい瞬間」にだけ、Apple 標準の評価の小窓を出す。
/// ・前回お願いしてから120日たつまでは出さない（しつこくしない）
/// ・実際に出すかどうかは最終的に Apple が決める（1年に3回まで等の制限がある）
/// ・Android は Google Play からのインストールでないと動かないため、iPhone だけで行う
class ReviewPrompter {
  static const String _lastAskedKey = 'review_last_asked_ms';
  static const Duration _interval = Duration(days: 120);

  static Future<void> maybeAskAfterPersonalBest() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final prefs = SharedPreferencesAsync();
      final lastAskedMs = await prefs.getInt(_lastAskedKey) ?? 0;
      final now = DateTime.now();
      final lastAsked = DateTime.fromMillisecondsSinceEpoch(lastAskedMs);
      if (now.difference(lastAsked) < _interval) return;

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await prefs.setInt(_lastAskedKey, now.millisecondsSinceEpoch);
      await review.requestReview();
    } catch (e) {
      debugPrint('評価のお願いエラー: $e');
    }
  }
}
