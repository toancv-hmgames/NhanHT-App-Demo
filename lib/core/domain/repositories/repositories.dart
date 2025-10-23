import '../entities/book.dart';
import '../entities/chapter_summary.dart';

abstract class CatalogRepository {
  Future<List<Book>> getBooks();
  Future<Book> getBookById(String bookId);
  Future<List<ChapterSummary>> listChapters(String bookId);

  Future<String> loadChapterText(String bookId, int chapterIdx);
  Future<List<Book>> searchBooks({String? q, List<String> genres});
}