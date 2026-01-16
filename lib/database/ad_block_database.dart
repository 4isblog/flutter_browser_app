import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ad_block_rule.dart';

class AdBlockDatabase {
  static final AdBlockDatabase _instance = AdBlockDatabase._internal();
  static Database? _database;

  factory AdBlockDatabase() {
    return _instance;
  }

  AdBlockDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ad_block.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 广告拦截规则订阅表
    await db.execute('''
      CREATE TABLE ad_block_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        url TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        ruleCount INTEGER NOT NULL DEFAULT 0,
        version TEXT
      )
    ''');

    // 广告拦截规则内容表
    await db.execute('''
      CREATE TABLE ad_block_filters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ruleId TEXT NOT NULL,
        filter TEXT NOT NULL,
        FOREIGN KEY (ruleId) REFERENCES ad_block_rules (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_filters_ruleId ON ad_block_filters(ruleId)
    ''');
  }

  /// 添加规则订阅
  Future<void> addRule(AdBlockRule rule) async {
    final db = await database;
    await db.insert(
      'ad_block_rules',
      {
        'id': rule.id,
        'name': rule.name,
        'description': rule.description,
        'url': rule.url,
        'enabled': rule.enabled ? 1 : 0,
        'createdAt': rule.createdAt.toIso8601String(),
        'updatedAt': rule.updatedAt.toIso8601String(),
        'ruleCount': rule.ruleCount,
        'version': rule.version,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有规则订阅
  Future<List<AdBlockRule>> getAllRules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ad_block_rules',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return AdBlockRule(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        description: maps[i]['description'] as String,
        url: maps[i]['url'] as String,
        enabled: maps[i]['enabled'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
        updatedAt: DateTime.parse(maps[i]['updatedAt'] as String),
        ruleCount: maps[i]['ruleCount'] as int,
        version: maps[i]['version'] as String?,
      );
    });
  }

  /// 获取启用的规则订阅
  Future<List<AdBlockRule>> getEnabledRules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ad_block_rules',
      where: 'enabled = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) {
      return AdBlockRule(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        description: maps[i]['description'] as String,
        url: maps[i]['url'] as String,
        enabled: maps[i]['enabled'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
        updatedAt: DateTime.parse(maps[i]['updatedAt'] as String),
        ruleCount: maps[i]['ruleCount'] as int,
        version: maps[i]['version'] as String?,
      );
    });
  }

  /// 更新规则订阅
  Future<void> updateRule(AdBlockRule rule) async {
    final db = await database;
    await db.update(
      'ad_block_rules',
      {
        'name': rule.name,
        'description': rule.description,
        'url': rule.url,
        'enabled': rule.enabled ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'ruleCount': rule.ruleCount,
        'version': rule.version,
      },
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  /// 切换规则启用状态
  Future<void> toggleRule(String id, bool enabled) async {
    final db = await database;
    await db.update(
      'ad_block_rules',
      {
        'enabled': enabled ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除规则订阅
  Future<void> deleteRule(String id) async {
    final db = await database;
    await db.delete(
      'ad_block_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
    // 同时删除相关的过滤规则
    await db.delete(
      'ad_block_filters',
      where: 'ruleId = ?',
      whereArgs: [id],
    );
  }

  /// 保存过滤规则
  Future<void> saveFilters(String ruleId, List<String> filters) async {
    final db = await database;
    
    // 先删除旧的过滤规则
    await db.delete(
      'ad_block_filters',
      where: 'ruleId = ?',
      whereArgs: [ruleId],
    );

    // 批量插入新的过滤规则
    final batch = db.batch();
    for (final filter in filters) {
      batch.insert('ad_block_filters', {
        'ruleId': ruleId,
        'filter': filter,
      });
    }
    await batch.commit(noResult: true);

    // 更新规则数量
    await db.update(
      'ad_block_rules',
      {
        'ruleCount': filters.length,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [ruleId],
    );
  }

  /// 获取所有启用的过滤规则
  Future<List<String>> getAllEnabledFilters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT f.filter
      FROM ad_block_filters f
      INNER JOIN ad_block_rules r ON f.ruleId = r.id
      WHERE r.enabled = 1
    ''');

    return maps.map((m) => m['filter'] as String).toList();
  }

  /// 清空所有规则
  Future<void> clearAllRules() async {
    final db = await database;
    await db.delete('ad_block_rules');
    await db.delete('ad_block_filters');
  }
}
