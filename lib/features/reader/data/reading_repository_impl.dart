import 'package:sqflite/sqflite.dart';
import '../../../core/data/data_sources/local_db.dart';
import '../../../core/domain/entities/chapter_summary.dart';
import '../../../core/domain/repositories/repositories.dart' as core_repo;
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
}
