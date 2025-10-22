import '../../domain/entities.dart';

class BookMapper {
  static Book fromRow(Map<String, Object?> row) => Book(
    id: row['id'] as String,
    title: row['title'] as String,
    author: row['author'] as String?,
    coverAsset: row['coverAsset'] as String?,
    genres: (row['genres'] as String?)?.split(',') ?? [],
  );
}
