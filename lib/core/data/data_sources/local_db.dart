import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static const _dbName = 'novel_reader.db';
  static const _dbVersion = 3;

  static const tableBook = 'book';
  static const tableSearch = 'search_index';
  static const tableMeta = '_meta';
  static const tableChapter = 'chapter';

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
            chapterCount INTEGER,
            updatedAt INTEGER,
            summary TEXT,
            rating REAL,
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
        await db.execute('''
          CREATE TABLE $tableChapter(
            bookId TEXT NOT NULL,
            idx INTEGER NOT NULL,
            id TEXT NOT NULL,
            title TEXT,
            path TEXT NOT NULL,
            length INTEGER,
            PRIMARY KEY(book_id, idx)
          );
          ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_chapters_book ON chapters(book_id);');
      },
    );
  }
}
