import 'entities.dart';
import 'repositories.dart';

class GetBooks {
  final CatalogRepository repo;

  GetBooks({required this.repo});

  Future<List<Book>> call() => repo.getBooks();
}

class SearchBooks {
  final CatalogRepository repo;

  SearchBooks({required this.repo});

  Future<List<Book>> call({String? q, List<String> genres = const []}) =>
      repo.searchBooks(q: q, genres: genres);
}
