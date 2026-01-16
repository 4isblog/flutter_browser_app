import 'package:flutter_browser/models/favorite_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FavoritesDatabase {
  static final FavoritesDatabase instance = FavoritesDatabase._init();
  static Database? _database;

  FavoritesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
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
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        favicon TEXT,
        addTime INTEGER NOT NULL
      )
    ''');
  }

  Future<int> addFavorite(FavoriteModel favorite) async {
    final db = await instance.database;
    
    return await db.insert(
      'favorites',
      {
        'url': favorite.url?.toString() ?? '',
        'title': favorite.title ?? '',
        'favicon': favorite.favicon?.url.toString(),
        'addTime': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FavoriteModel>> getAllFavorites() async {
    final db = await instance.database;
    
    final result = await db.query(
      'favorites',
      orderBy: 'addTime DESC',
    );

    return result.map((json) => FavoriteModel.fromMap({
      'url': json['url'],
      'title': json['title'],
      'favicon': json['favicon'] != null ? {
        'url': json['favicon'],
      } : null,
    })!).toList();
  }

  Future<bool> isFavorite(String url) async {
    final db = await instance.database;
    
    final result = await db.query(
      'favorites',
      where: 'url = ?',
      whereArgs: [url],
    );

    return result.isNotEmpty;
  }

  Future<int> deleteFavorite(String url) async {
    final db = await instance.database;
    
    return await db.delete(
      'favorites',
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  Future<int> deleteAllFavorites() async {
    final db = await instance.database;
    return await db.delete('favorites');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
