import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/entities/book.dart';

class DiscoverState {
  final AsyncValue<List<Book>> books;

  const DiscoverState({this.books = const AsyncLoading()});

  DiscoverState copyWith({AsyncValue<List<Book>>? books}) =>
      DiscoverState(books: books ?? this.books);
}
