import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/book.dart';

class BookDetailState {
  final AsyncValue<List<Book>> books;

  const BookDetailState({this.books = const AsyncLoading()});

  BookDetailState copyWith({AsyncValue<List<Book>>? books}) =>
      BookDetailState(books: books ?? this.books);
}
