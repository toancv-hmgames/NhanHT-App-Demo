// lib/features/discover/data/data_sources/local_db.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static const _dbName = 'novel_reader.db';
  static const _dbVersion = 4;

  static const tableBook = 'book';
  static const tableSearch = 'search_index';
  static const tableMeta = '_meta';
  static const tableChapter = 'chapter';
  static const tableReadingProgress = 'reading_progress';
  static const appSettings = 'app_settings';
  static const reader_prefs = 'reader_prefs';

  static Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $tableBook(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT,
            coverAsset TEXT,
            genres TEXT,
            chapterCount INTEGER NOT NULL,
            updatedAt INTEGER,
            summary TEXT,
            rating REAL
          );
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
            title TEXT,
            assetPath TEXT NOT NULL,
            length INTEGER,
            PRIMARY KEY(bookId, idx),
            FOREIGN KEY(bookId) REFERENCES $tableBook(id) ON DELETE CASCADE
          );
        ''');

        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_chapter_book ON $tableChapter(bookId);');
        // await db.execute('''
        //   CREATE TABLE $appSettings (
        //   key TEXT PRIMARY KEY,
        //   value TEXT NOT NULL
        // );
        // ''');
        await db.execute('''
          CREATE TABLE $tableReadingProgress(
            bookId TEXT PRIMARY KEY,
            chapterIdx INTEGER NOT NULL,
            scrollOffset REAL NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE $reader_prefs (
          id INTEGER PRIMARY KEY CHECK (id = 0),
          font_px REAL NOT NULL,
          theme_mode TEXT NOT NULL,
          reading_mode TEXT NOT NULL
        );
        ''');
      },
      onUpgrade: (Database db, int oldV, int newV) async {
        // NOTE QUAN TRỌNG:
        // KHÔNG còn ALTER TABLE book ADD COLUMN summary/rating ở đây nữa.

        // chỉ lo vụ reading_progress nếu DB cũ chưa có
        if (oldV < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableReadingProgress(
              bookId TEXT PRIMARY KEY,
              chapterIdx INTEGER NOT NULL,
              scrollOffset REAL NOT NULL DEFAULT 0
            );
          ''');
        }
        if (oldV < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $reader_prefs (
              id INTEGER PRIMARY KEY CHECK (id = 0),
              font_px REAL NOT NULL,
              theme_mode TEXT NOT NULL,
              reading_mode TEXT NOT NULL
            );
          ''');
        }
      },
    );
  }
}
