import '../../domain/entities/book.dart';

class BookMapper {
  static Book fromRow(Map<String, Object?> row) => Book(
    summary: row['summary'] as String?,
    rating: (row['rating'] as num?)?.toDouble(),
    chapterCount: (row['chapterCount'] as num?)?.toInt() ?? 0,
    updateAtMillis: (row['updatedAt'] as num?)?.toInt(),
    id: row['id'] as String,
    title: row['title'] as String,
    author: row['author'] as String?,
    coverAsset: row['coverAsset'] as String?,
    genres: (row['genres'] as String?)?.split(',') ?? [],
  );
}
