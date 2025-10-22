import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static const _dbName = 'novel_reader.db';
  static const _dbVersion = 1;

  static const tableBook = 'book';
  static const tableSearch = 'search_index';
  static const tableMeta = '_meta';

  static Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $tableBook(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT,
            coverAsset TEXT,
            genres TEXT,
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableSearch(
  bookId TEXT PRIMARY KEY,
  title TEXT,
  author TEXT,
  genres TEXT
);
        ''');
        await db.execute(
            'CREATE TABLE $tableMeta(key TEXT PRIMARY KEY, value TEXT)');
      },
    );
  }
}
