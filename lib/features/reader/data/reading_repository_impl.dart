import 'package:sqflite/sqflite.dart';
import '../../../core/data/data_sources/local_db.dart';
import '../../../core/domain/entities/chapter_summary.dart';
import '../../../core/domain/repositories/repositories.dart' as core_repo;
import '../../../share/const_value.dart';
import '../domain/entities/reader_pref.dart';
import '../domain/reading_repository.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  final Database _db;
  final core_repo.CatalogRepository _catalog;

  ReadingRepositoryImpl(this._db, this._catalog);

  @override
  Future<List<ChapterSummary>> listChapters(String bookId) {
    return _catalog.listChapters(bookId);
  }

  @override
  Future<String> loadChapterText(String bookId, int chapterIdx) {
    return _catalog.loadChapterText(bookId, chapterIdx);
  }

  @override
  Future<ReaderSession?> loadSession(String bookId) async {
    final rows = await _db.query(
      LocalDb.tableReadingProgress,
      where: 'bookId = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return ReaderSession(
      bookId: r['bookId'] as String,
      chapterIdx: (r['chapterIdx'] as num).toInt(),
      scrollOffset: (r['scrollOffset'] as num).toDouble(),
    );
  }

  @override
  Future<void> saveSession(ReaderSession s) async {
    await _db.insert(
      LocalDb.tableReadingProgress,
      {
        'bookId': s.bookId,
        'chapterIdx': s.chapterIdx,
        'scrollOffset': s.scrollOffset,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<ReaderPrefs?> loadGlobalReaderPrefs() async {
    final db = _db; // Database được inject vào repo

    final rows = await db.query(
      'reader_prefs',
      where: 'id = 0',
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;

    return ReaderPrefs(
      fontPx: row['font_px'] as double,
      themeMode: (row['theme_mode'] as String) == 'dark'
          ? ReaderThemeMode.dark
          : ReaderThemeMode.light,
      readingMode: (row['reading_mode'] as String) == 'slide'
          ? ReaderReadingMode.slide
          : ReaderReadingMode.scroll,
    );
  }

  @override
  Future<void> saveGlobalReaderPrefs(ReaderPrefs prefs) async {
    final db = _db;

    await db.insert(
      'reader_prefs',
      {
        'id': 0,
        'font_px': prefs.fontPx,
        'theme_mode':
            prefs.themeMode == ReaderThemeMode.dark ? 'dark' : 'light',
        'reading_mode':
            prefs.readingMode == ReaderReadingMode.slide ? 'slide' : 'scroll',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
