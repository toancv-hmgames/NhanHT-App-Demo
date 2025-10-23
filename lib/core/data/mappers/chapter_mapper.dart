import '../../domain/entities/chapter_summary.dart';

class ChapterMapper {
  static ChapterSummary fromRow(Map<String, Object?> r) => ChapterSummary(
    bookId: r['book_id'] as String,
    idx: (r['idx'] as num).toInt(),
    id: r['id'] as String,
    title: r['title'] as String?,
    path: r['path'] as String,
    length: (r['length'] as num?)?.toInt(),
  );
}
