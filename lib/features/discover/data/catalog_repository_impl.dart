import 'package:sqflite/sqflite.dart';

import '../domain/entities.dart';
import '../domain/repositories.dart';
import 'data_sources/local_db.dart';
import 'mappers/book_mapper.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final Database db;
  CatalogRepositoryImpl(this.db);

  @override
  Future<List<Book>> getBooks() async {
    final rows = await db.query(LocalDb.tableBook, orderBy: 'title ASC');
    return rows.map(BookMapper.fromRow).toList();
  }

  @override
  Future<List<Book>> searchBooks({String? q, List<String> genres = const []}) async {
    if (q == null || q.isEmpty) {
      return getBooks();
    }
    final rows = await db.query(
      LocalDb.tableSearch,
      where: 'title MATCH ?',
      whereArgs: ['*$q*'],
    );
    final ids = rows.map((r) => r['bookId'] as String).toList();
    final books = await db.query(LocalDb.tableBook,
        where: 'id IN (${List.filled(ids.length, '?').join(',')})', whereArgs: ids);
    return books.map(BookMapper.fromRow).toList();
  }
}
