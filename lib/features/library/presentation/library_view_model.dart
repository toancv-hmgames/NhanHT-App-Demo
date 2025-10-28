import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/domain/usecases.dart';
import 'library_state.dart';

class LibraryVM extends StateNotifier<LibraryState> {
  final GetBooks _getBooks;

  LibraryVM(this._getBooks) : super(const LibraryState()) {
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

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void clearQuery() {
    state = state.copyWith(query: '');
  }

  void setTab(int idx) {
    state = state.copyWith(tabIndex: idx);
  }
}
