import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/entities/book.dart';

class LibraryState {
  final AsyncValue<List<Book>> books;

  /// text user gõ trong ô search
  final String query;

  /// 0 = Reading, 1 = Viewed
  final int tabIndex;

  const LibraryState({
    this.books = const AsyncLoading(),
    this.query = '',
    this.tabIndex = 0,
  });

  LibraryState copyWith({
    AsyncValue<List<Book>>? books,
    String? query,
    int? tabIndex,
  }) {
    return LibraryState(
      books: books ?? this.books,
      query: query ?? this.query,
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }
}
