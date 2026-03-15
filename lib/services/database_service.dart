/// メモリ上でデータを管理するサービス
/// （Web版でもすぐ動く。スマホ版に移行時にsqfliteに置き換え可能）
class DatabaseService {
  // --- メモリ上のデータストア ---
  static int _nextChildId = 1;
  static int _nextSessionId = 1;
  static int _nextRunId = 1;
  static int _nextRunResultId = 1;
  static int _nextCourseId = 1;

  static final List<Map<String, dynamic>> _children = [];
  static final List<Map<String, dynamic>> _sessions = [];
  static final List<Map<String, dynamic>> _runs = [];
  static final List<Map<String, dynamic>> _runResults = [];
  static final List<Map<String, dynamic>> _courses = [];

  // --- 子ども関連 ---

  static Future<int> addChild(String name) async {
    final id = _nextChildId++;
    _children.add({
      'id': id,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  static Future<List<Map<String, dynamic>>> getChildren() async {
    return List.from(_children)..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  static Future<void> deleteChild(int id) async {
    _children.removeWhere((c) => c['id'] == id);
  }

  // --- セッション関連 ---

  static Future<int> getTodaySessionId() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    for (final session in _sessions) {
      if (session['date'] == today) {
        return session['id'] as int;
      }
    }

    final id = _nextSessionId++;
    _sessions.add({
      'id': id,
      'date': today,
      'name': '$today の練習',
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  // --- 走行結果関連 ---

  static Future<int> addRun({
    required int sessionId,
    required String startSoundType,
  }) async {
    final id = _nextRunId++;
    _runs.add({
      'id': id,
      'session_id': sessionId,
      'start_at': DateTime.now().toIso8601String(),
      'start_sound_type': startSoundType,
      'status': 'done',
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  static Future<void> addRunResult({
    required int runId,
    required int childId,
    required int timeMs,
  }) async {
    _runResults.add({
      'id': _nextRunResultId++,
      'run_id': runId,
      'child_id': childId,
      'time_ms': timeMs,
    });
  }

  static Future<List<Map<String, dynamic>>> getTodayResults(int childId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 今日のセッションIDを取得
    final todaySessionIds = _sessions
        .where((s) => s['date'] == today)
        .map((s) => s['id'] as int)
        .toSet();

    // 今日のランを取得
    final todayRunIds = _runs
        .where((r) =>
            todaySessionIds.contains(r['session_id']) &&
            r['status'] == 'done')
        .map((r) => r['id'] as int)
        .toSet();

    // 該当する結果を取得
    final results = _runResults
        .where((rr) =>
            todayRunIds.contains(rr['run_id']) &&
            rr['child_id'] == childId)
        .toList();

    return results;
  }

  static Future<void> deleteRunResult(int runResultId) async {
    _runResults.removeWhere((rr) => rr['id'] == runResultId);
  }

  static Future<int?> getAllTimeBest(int childId) async {
    final doneRunIds = _runs
        .where((r) => r['status'] == 'done')
        .map((r) => r['id'] as int)
        .toSet();

    final times = _runResults
        .where((rr) =>
            doneRunIds.contains(rr['run_id']) &&
            rr['child_id'] == childId)
        .map((rr) => rr['time_ms'] as int)
        .toList();

    if (times.isEmpty) return null;
    return times.reduce((a, b) => a < b ? a : b);
  }

  // --- コース関連 ---

  static Future<int> saveCourse({
    String? name,
    double? lengthM,
    double? firstStraightM,
    int? curveCount,
    String? surface,
    String? weather,
    String? note,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 今日のコースがあれば更新
    for (int i = 0; i < _courses.length; i++) {
      if (_courses[i]['date'] == today) {
        _courses[i] = {
          ..._courses[i],
          'name': name,
          'length_m': lengthM,
          'first_straight_m': firstStraightM,
          'curve_count': curveCount,
          'surface': surface,
          'weather': weather,
          'note': note,
        };
        return _courses[i]['id'] as int;
      }
    }

    // なければ新規作成
    final id = _nextCourseId++;
    _courses.add({
      'id': id,
      'date': today,
      'name': name,
      'length_m': lengthM,
      'first_straight_m': firstStraightM,
      'curve_count': curveCount,
      'surface': surface,
      'weather': weather,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  static Future<Map<String, dynamic>?> getTodayCourse() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final course in _courses) {
      if (course['date'] == today) return course;
    }
    return null;
  }
}
