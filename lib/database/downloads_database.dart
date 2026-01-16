import 'package:flutter_browser/models/download_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DownloadsDatabase {
  static final DownloadsDatabase instance = DownloadsDatabase._init();
  static Database? _database;

  DownloadsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('downloads.db');
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
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        totalBytes INTEGER DEFAULT 0,
        downloadedBytes INTEGER DEFAULT 0,
        status TEXT DEFAULT 'downloading',
        startTime INTEGER NOT NULL,
        endTime INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_startTime ON downloads(startTime DESC)');
  }

  Future<int> addDownload(DownloadModel download) async {
    final db = await database;
    return await db.insert('downloads', download.toMap());
  }

  Future<List<DownloadModel>> getAllDownloads() async {
    final db = await database;
    final result = await db.query(
      'downloads',
      orderBy: 'startTime DESC',
    );
    return result.map((map) => DownloadModel.fromMap(map)).toList();
  }

  Future<DownloadModel?> getDownload(int id) async {
    final db = await database;
    final result = await db.query(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return DownloadModel.fromMap(result.first);
  }

  Future<int> updateDownload(DownloadModel download) async {
    final db = await database;
    return await db.update(
      'downloads',
      download.toMap(),
      where: 'id = ?',
      whereArgs: [download.id],
    );
  }

  Future<int> deleteDownload(int id) async {
    final db = await database;
    return await db.delete(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllDownloads() async {
    final db = await database;
    return await db.delete('downloads');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
