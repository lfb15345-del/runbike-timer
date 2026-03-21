import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web用のデータベースサービス（インメモリ＋localStorage）
/// ブラウザを閉じてもlocalStorageにデータが残る
class DatabaseService {
  /// 現在選択中の子ども（計測タブと解析タブで共有）
  static int? selectedChildId;
  static String? selectedChildName;

  // --- インメモリデータ ---
  static List<Map<String, dynamic>> _children = [];
  static List<Map<String, dynamic>> _sessions = [];
  static List<Map<String, dynamic>> _runs = [];
  static List<Map<String, dynamic>> _runResults = [];
  static List<Map<String, dynamic>> _courses = [];
  static int _nextId = 1;

  /// 初期化（localStorageからデータを復元）
  static Future<void> init() async {
    _loadFromStorage();
  }

  // --- localStorage 永続化 ---

  static void _saveToStorage() {
    final data = {
      'children': _children,
      'sessions': _sessions,
      'runs': _runs,
      'runResults': _runResults,
      'courses': _courses,
      'nextId': _nextId,
    };
    html.window.localStorage['runbike_db'] = jsonEncode(data);
  }

  static void _loadFromStorage() {
    final stored = html.window.localStorage['runbike_db'];
    if (stored == null) return;

    try {
      final data = jsonDecode(stored) as Map<String, dynamic>;
      _children = List<Map<String, dynamic>>.from(
        (data['children'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
      _sessions = List<Map<String, dynamic>>.from(
        (data['sessions'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
      _runs = List<Map<String, dynamic>>.from(
        (data['runs'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
      _runResults = List<Map<String, dynamic>>.from(
        (data['runResults'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
      _courses = List<Map<String, dynamic>>.from(
        (data['courses'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
      _nextId = data['nextId'] as int;
    } catch (_) {
      // データ破損時はリセット
    }
  }

  static int _genId() => _nextId++;

  // --- 子ども関連 ---

  static Future<int> addChild(String name) async {
    final id = _genId();
    _children.add({
      'id': id,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
    _children.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    _saveToStorage();
    return id;
  }

  static Future<List<Map<String, dynamic>>> getChildren() async {
    return List.from(_children);
  }

  static Future<void> updateChildName(int id, String newName) async {
    final child = _children.firstWhere((c) => c['id'] == id, orElse: () => {});
    if (child.isNotEmpty) {
      child['name'] = newName;
      _saveToStorage();
    }
  }

  static Future<void> deleteChild(int id) async {
    _children.removeWhere((c) => c['id'] == id);
    _saveToStorage();
  }

  // --- セッション関連 ---

  static Future<int> getTodaySessionId() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = _sessions.where((s) => s['date'] == today);
    if (existing.isNotEmpty) return existing.first['id'] as int;

    final id = _genId();
    _sessions.add({
      'id': id,
      'date': today,
      'name': '$today の練習',
      'created_at': DateTime.now().toIso8601String(),
    });
    _saveToStorage();
    return id;
  }

  // --- 走行結果関連 ---

  static Future<int> addRun({
    required int sessionId,
    required String startSoundType,
  }) async {
    final id = _genId();
    _runs.add({
      'id': id,
      'session_id': sessionId,
      'start_at': DateTime.now().toIso8601String(),
      'start_sound_type': startSoundType,
      'status': 'done',
      'created_at': DateTime.now().toIso8601String(),
    });
    _saveToStorage();
    return id;
  }

  static Future<void> addRunResult({
    required int runId,
    required int childId,
    required int timeMs,
  }) async {
    final id = _genId();
    _runResults.add({
      'id': id,
      'run_id': runId,
      'child_id': childId,
      'time_ms': timeMs,
      'max_speed_kmh': null,
      'avg_speed_kmh': null,
    });
    _saveToStorage();
  }

  static Future<List<Map<String, dynamic>>> getTodayResults(int childId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todaySessionIds = _sessions
        .where((s) => s['date'] == today)
        .map((s) => s['id'] as int)
        .toSet();
    final todayRunIds = _runs
        .where((r) => todaySessionIds.contains(r['session_id']) && r['status'] == 'done')
        .map((r) => r['id'] as int)
        .toSet();

    return _runResults
        .where((rr) => todayRunIds.contains(rr['run_id']) && rr['child_id'] == childId)
        .toList();
  }

  static Future<void> deleteRunResult(int runResultId) async {
    _runResults.removeWhere((rr) => rr['id'] == runResultId);
    _saveToStorage();
  }

  /// 走行結果のスピードデータを更新
  static Future<void> updateRunResultSpeed({
    required int runResultId,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
  }) async {
    final rr = _runResults.firstWhere((r) => r['id'] == runResultId, orElse: () => {});
    if (rr.isNotEmpty) {
      rr['max_speed_kmh'] = maxSpeedKmh;
      rr['avg_speed_kmh'] = avgSpeedKmh;
      _saveToStorage();
    }
  }

  static Future<int?> getAllTimeBest(int childId) async {
    final results = _runResults.where((rr) {
      if (rr['child_id'] != childId) return false;
      final run = _runs.firstWhere((r) => r['id'] == rr['run_id'], orElse: () => {});
      return run.isNotEmpty && run['status'] == 'done';
    });
    if (results.isEmpty) return null;
    return results.map((r) => r['time_ms'] as int).reduce((a, b) => a < b ? a : b);
  }

  /// 歴代最高速度を取得
  static Future<double?> getAllTimeBestMaxSpeed(int childId) async {
    final results = _runResults.where((rr) {
      if (rr['child_id'] != childId) return false;
      if (rr['max_speed_kmh'] == null) return false;
      final run = _runs.firstWhere((r) => r['id'] == rr['run_id'], orElse: () => {});
      return run.isNotEmpty && run['status'] == 'done';
    });
    if (results.isEmpty) return null;
    return results
        .map((r) => (r['max_speed_kmh'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  /// 歴代最高平均速度を取得
  static Future<double?> getAllTimeBestAvgSpeed(int childId) async {
    final results = _runResults.where((rr) {
      if (rr['child_id'] != childId) return false;
      if (rr['avg_speed_kmh'] == null) return false;
      final run = _runs.firstWhere((r) => r['id'] == rr['run_id'], orElse: () => {});
      return run.isNotEmpty && run['status'] == 'done';
    });
    if (results.isEmpty) return null;
    return results
        .map((r) => (r['avg_speed_kmh'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
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

    final existingIdx = _courses.indexWhere((c) => c['date'] == today);

    final data = {
      'name': name,
      'length_m': lengthM,
      'first_straight_m': firstStraightM,
      'curve_count': curveCount,
      'surface': surface,
      'weather': weather,
      'note': note,
    };

    if (existingIdx >= 0) {
      _courses[existingIdx] = {..._courses[existingIdx], ...data};
      _saveToStorage();
      return _courses[existingIdx]['id'] as int;
    }

    final id = _genId();
    _courses.add({
      ...data,
      'id': id,
      'date': today,
      'created_at': DateTime.now().toIso8601String(),
    });
    _saveToStorage();
    return id;
  }

  static Future<Map<String, dynamic>?> getTodayCourse() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final results = _courses.where((c) => c['date'] == today);
    return results.isNotEmpty ? Map.from(results.first) : null;
  }
}
