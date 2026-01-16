import 'package:flutter_browser/models/browser_history.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HistoryDatabase {
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  HistoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('browser_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        favicon TEXT,
        visitTime INTEGER NOT NULL
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('CREATE INDEX idx_visitTime ON history(visitTime DESC)');
    await db.execute('CREATE INDEX idx_url ON history(url)');
  }

  // 添加历史记录
  Future<int> addHistory(BrowserHistory history) async {
    final db = await database;
    return await db.insert('history', history.toMap());
  }

  // 获取所有历史记录（按时间倒序）
  Future<List<BrowserHistory>> getAllHistory({int? limit}) async {
    final db = await database;
    final result = await db.query(
      'history',
      orderBy: 'visitTime DESC',
      limit: limit,
    );
    return result.map((map) => BrowserHistory.fromMap(map)).toList();
  }

  // 按日期分组获取历史记录
  Future<Map<String, List<BrowserHistory>>> getHistoryGroupedByDate() async {
    final db = await database;
    final result = await db.query(
      'history',
      orderBy: 'visitTime DESC',
    );

    final histories = result.map((map) => BrowserHistory.fromMap(map)).toList();
    final Map<String, List<BrowserHistory>> grouped = {};

    for (var history in histories) {
      final date = _formatDate(history.visitTime);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(history);
    }

    return grouped;
  }

  // 搜索历史记录
  Future<List<BrowserHistory>> searchHistory(String query) async {
    final db = await database;
    final result = await db.query(
      'history',
      where: 'url LIKE ? OR title LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'visitTime DESC',
    );
    return result.map((map) => BrowserHistory.fromMap(map)).toList();
  }

  // 删除单条历史记录
  Future<int> deleteHistory(int id) async {
    final db = await database;
    return await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除指定URL的所有历史记录
  Future<int> deleteHistoryByUrl(String url) async {
    final db = await database;
    return await db.delete(
      'history',
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  // 清空所有历史记录
  Future<int> clearAllHistory() async {
    final db = await database;
    return await db.delete('history');
  }

  // 删除指定时间范围的历史记录
  Future<int> deleteHistoryByTimeRange(DateTime start, DateTime end) async {
    final db = await database;
    return await db.delete(
      'history',
      where: 'visitTime >= ? AND visitTime <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
  }

  // 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == yesterday) {
      return '昨天';
    } else if (now.difference(date).inDays < 7) {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }

  // 关闭数据库
  Future close() async {
    final db = await database;
    db.close();
  }
}
