import 'entities.dart';

abstract class CatalogRepository {
  Future<List<Book>> getBooks();
  Future<List<Book>> searchBooks({String? q, List<String> genres});
}