import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/entities.dart';
import '../domain/usecases.dart';

class DiscoverState {
  final AsyncValue<List<Book>> books;
  const DiscoverState({this.books = const AsyncLoading()});

  DiscoverState copyWith({AsyncValue<List<Book>>? books}) =>
      DiscoverState(books: books ?? this.books);
}

class DiscoverVM extends StateNotifier<DiscoverState> {
  final GetBooks _getBooks;

  DiscoverVM(this._getBooks) : super(const DiscoverState()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final list = await _getBooks();
      state = state.copyWith(books: AsyncData(list));
    } catch (e, st) {
      state = state.copyWith(books: AsyncError(e, st));
    }
  }
}
