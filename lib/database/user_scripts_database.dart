import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_script_model.dart';

class UserScriptsDatabase {
  static final UserScriptsDatabase _instance = UserScriptsDatabase._internal();
  static Database? _database;

  factory UserScriptsDatabase() {
    return _instance;
  }

  UserScriptsDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'user_scripts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_scripts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        code TEXT NOT NULL,
        matchUrls TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        author TEXT,
        version TEXT,
        icon TEXT
      )
    ''');
  }

  /// 添加脚本
  Future<void> addScript(UserScriptModel script) async {
    final db = await database;
    await db.insert(
      'user_scripts',
      {
        'id': script.id,
        'name': script.name,
        'description': script.description,
        'code': script.code,
        'matchUrls': jsonEncode(script.matchUrls),
        'enabled': script.enabled ? 1 : 0,
        'createdAt': script.createdAt.toIso8601String(),
        'updatedAt': script.updatedAt.toIso8601String(),
        'author': script.author,
        'version': script.version,
        'icon': script.icon,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有脚本
  Future<List<UserScriptModel>> getAllScripts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_scripts',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return UserScriptModel(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        description: maps[i]['description'] as String,
        code: maps[i]['code'] as String,
        matchUrls: (jsonDecode(maps[i]['matchUrls'] as String) as List).cast<String>(),
        enabled: maps[i]['enabled'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
        updatedAt: DateTime.parse(maps[i]['updatedAt'] as String),
        author: maps[i]['author'] as String?,
        version: maps[i]['version'] as String?,
        icon: maps[i]['icon'] as String?,
      );
    });
  }

  /// 获取启用的脚本
  Future<List<UserScriptModel>> getEnabledScripts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_scripts',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return UserScriptModel(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        description: maps[i]['description'] as String,
        code: maps[i]['code'] as String,
        matchUrls: (jsonDecode(maps[i]['matchUrls'] as String) as List).cast<String>(),
        enabled: maps[i]['enabled'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
        updatedAt: DateTime.parse(maps[i]['updatedAt'] as String),
        author: maps[i]['author'] as String?,
        version: maps[i]['version'] as String?,
        icon: maps[i]['icon'] as String?,
      );
    });
  }

  /// 根据 URL 获取匹配的脚本
  Future<List<UserScriptModel>> getScriptsForUrl(String url) async {
    final enabledScripts = await getEnabledScripts();
    return enabledScripts.where((script) => script.matchesUrl(url)).toList();
  }

  /// 获取单个脚本
  Future<UserScriptModel?> getScript(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_scripts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return UserScriptModel(
      id: maps[0]['id'] as String,
      name: maps[0]['name'] as String,
      description: maps[0]['description'] as String,
      code: maps[0]['code'] as String,
      matchUrls: (jsonDecode(maps[0]['matchUrls'] as String) as List).cast<String>(),
      enabled: maps[0]['enabled'] == 1,
      createdAt: DateTime.parse(maps[0]['createdAt'] as String),
      updatedAt: DateTime.parse(maps[0]['updatedAt'] as String),
      author: maps[0]['author'] as String?,
      version: maps[0]['version'] as String?,
      icon: maps[0]['icon'] as String?,
    );
  }

  /// 根据名称获取脚本
  Future<UserScriptModel?> getScriptByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_scripts',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;

    return UserScriptModel(
      id: maps[0]['id'] as String,
      name: maps[0]['name'] as String,
      description: maps[0]['description'] as String,
      code: maps[0]['code'] as String,
      matchUrls: (jsonDecode(maps[0]['matchUrls'] as String) as List).cast<String>(),
      enabled: maps[0]['enabled'] == 1,
      createdAt: DateTime.parse(maps[0]['createdAt'] as String),
      updatedAt: DateTime.parse(maps[0]['updatedAt'] as String),
      author: maps[0]['author'] as String?,
      version: maps[0]['version'] as String?,
      icon: maps[0]['icon'] as String?,
    );
  }

  /// 更新脚本
  Future<void> updateScript(UserScriptModel script) async {
    final db = await database;
    await db.update(
      'user_scripts',
      {
        'name': script.name,
        'description': script.description,
        'code': script.code,
        'matchUrls': jsonEncode(script.matchUrls),
        'enabled': script.enabled ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'author': script.author,
        'version': script.version,
        'icon': script.icon,
      },
      where: 'id = ?',
      whereArgs: [script.id],
    );
  }

  /// 切换脚本启用状态
  Future<void> toggleScript(String id, bool enabled) async {
    final db = await database;
    await db.update(
      'user_scripts',
      {
        'enabled': enabled ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除脚本
  Future<void> deleteScript(String id) async {
    final db = await database;
    await db.delete(
      'user_scripts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有脚本
  Future<void> clearAllScripts() async {
    final db = await database;
    await db.delete('user_scripts');
  }
}
