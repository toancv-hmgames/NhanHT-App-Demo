import '../../../core/domain/entities/chapter_summary.dart';

class ReaderSession {
  final String bookId;
  final int chapterIdx;
  final double scrollOffset;

  const ReaderSession({
    required this.bookId,
    required this.chapterIdx,
    required this.scrollOffset,
  });
}

abstract class ReadingRepository {
  // lấy metadata chương + nội dung chương (reuse CatalogRepository)
  Future<List<ChapterSummary>> listChapters(String bookId);
  Future<String> loadChapterText(String bookId, int chapterIdx);

  // load / save progress đọc
  Future<ReaderSession?> loadSession(String bookId);
  Future<void> saveSession(ReaderSession session);
}
