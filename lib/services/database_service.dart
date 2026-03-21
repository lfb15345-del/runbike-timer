import 'package:sqflite/sqflite.dart';

/// sqflite を使ったデータ永続化サービス
/// アプリを閉じてもデータが残る
class DatabaseService {
  static Database? _db;

  /// 現在選択中の子ども（計測タブと解析タブで共有）
  static int? selectedChildId;
  static String? selectedChildName;

  /// DB初期化（アプリ起動時に1回呼ぶ）
  static Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/runbike.db',
      version: 2,
      onCreate: (db, version) async {
        // 子どもテーブル
        await db.execute('''
          CREATE TABLE child (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        // セッションテーブル（日ごと）
        await db.execute('''
          CREATE TABLE session (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            name TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        // 走行テーブル
        await db.execute('''
          CREATE TABLE run (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            start_at TEXT NOT NULL,
            start_sound_type TEXT,
            status TEXT NOT NULL DEFAULT 'done',
            created_at TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES session(id)
          )
        ''');
        // 走行結果テーブル（v2: 速度カラム追加）
        await db.execute('''
          CREATE TABLE run_result (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            run_id INTEGER NOT NULL,
            child_id INTEGER NOT NULL,
            time_ms INTEGER NOT NULL,
            max_speed_kmh REAL,
            avg_speed_kmh REAL,
            FOREIGN KEY (run_id) REFERENCES run(id),
            FOREIGN KEY (child_id) REFERENCES child(id)
          )
        ''');
        // コーステーブル
        await db.execute('''
          CREATE TABLE course (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            name TEXT,
            length_m REAL,
            first_straight_m REAL,
            curve_count INTEGER,
            surface TEXT,
            weather TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1→v2: 速度データ用のカラムを追加
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE run_result ADD COLUMN max_speed_kmh REAL');
          await db.execute('ALTER TABLE run_result ADD COLUMN avg_speed_kmh REAL');
        }
      },
    );
  }

  // --- 子ども関連 ---

  static Future<int> addChild(String name) async {
    return await _db!.insert('child', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getChildren() async {
    return await _db!.query('child', orderBy: 'name ASC');
  }

  static Future<void> updateChildName(int id, String newName) async {
    await _db!.update(
      'child',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteChild(int id) async {
    await _db!.delete('child', where: 'id = ?', whereArgs: [id]);
  }

  // --- セッション関連 ---

  static Future<int> getTodaySessionId() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final results = await _db!.query(
      'session',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (results.isNotEmpty) {
      return results.first['id'] as int;
    }

    return await _db!.insert('session', {
      'date': today,
      'name': '$today の練習',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- 走行結果関連 ---

  static Future<int> addRun({
    required int sessionId,
    required String startSoundType,
  }) async {
    return await _db!.insert('run', {
      'session_id': sessionId,
      'start_at': DateTime.now().toIso8601String(),
      'start_sound_type': startSoundType,
      'status': 'done',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> addRunResult({
    required int runId,
    required int childId,
    required int timeMs,
  }) async {
    await _db!.insert('run_result', {
      'run_id': runId,
      'child_id': childId,
      'time_ms': timeMs,
    });
  }

  static Future<List<Map<String, dynamic>>> getTodayResults(int childId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await _db!.rawQuery('''
      SELECT rr.* FROM run_result rr
      INNER JOIN run r ON rr.run_id = r.id
      INNER JOIN session s ON r.session_id = s.id
      WHERE s.date = ? AND rr.child_id = ? AND r.status = 'done'
      ORDER BY rr.id ASC
    ''', [today, childId]);
  }

  static Future<void> deleteRunResult(int runResultId) async {
    await _db!.delete('run_result', where: 'id = ?', whereArgs: [runResultId]);
  }

  /// 走行結果のスピードデータを更新
  static Future<void> updateRunResultSpeed({
    required int runResultId,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
  }) async {
    await _db!.update(
      'run_result',
      {
        'max_speed_kmh': maxSpeedKmh,
        'avg_speed_kmh': avgSpeedKmh,
      },
      where: 'id = ?',
      whereArgs: [runResultId],
    );
  }

  static Future<int?> getAllTimeBest(int childId) async {
    final results = await _db!.rawQuery('''
      SELECT MIN(rr.time_ms) as best FROM run_result rr
      INNER JOIN run r ON rr.run_id = r.id
      WHERE rr.child_id = ? AND r.status = 'done'
    ''', [childId]);

    if (results.isNotEmpty && results.first['best'] != null) {
      return results.first['best'] as int;
    }
    return null;
  }

  /// 歴代最高速度を取得
  static Future<double?> getAllTimeBestMaxSpeed(int childId) async {
    final results = await _db!.rawQuery('''
      SELECT MAX(rr.max_speed_kmh) as best FROM run_result rr
      INNER JOIN run r ON rr.run_id = r.id
      WHERE rr.child_id = ? AND r.status = 'done' AND rr.max_speed_kmh IS NOT NULL
    ''', [childId]);
    if (results.isNotEmpty && results.first['best'] != null) {
      return results.first['best'] as double;
    }
    return null;
  }

  /// 歴代最高平均速度を取得
  static Future<double?> getAllTimeBestAvgSpeed(int childId) async {
    final results = await _db!.rawQuery('''
      SELECT MAX(rr.avg_speed_kmh) as best FROM run_result rr
      INNER JOIN run r ON rr.run_id = r.id
      WHERE rr.child_id = ? AND r.status = 'done' AND rr.avg_speed_kmh IS NOT NULL
    ''', [childId]);
    if (results.isNotEmpty && results.first['best'] != null) {
      return results.first['best'] as double;
    }
    return null;
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

    final existing = await _db!.query(
      'course',
      where: 'date = ?',
      whereArgs: [today],
    );

    final data = {
      'name': name,
      'length_m': lengthM,
      'first_straight_m': firstStraightM,
      'curve_count': curveCount,
      'surface': surface,
      'weather': weather,
      'note': note,
    };

    // 今日のコースがあれば更新
    if (existing.isNotEmpty) {
      await _db!.update('course', data, where: 'date = ?', whereArgs: [today]);
      return existing.first['id'] as int;
    }

    // なければ新規作成
    return await _db!.insert('course', {
      ...data,
      'date': today,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getTodayCourse() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final results = await _db!.query(
      'course',
      where: 'date = ?',
      whereArgs: [today],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
