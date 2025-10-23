import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/domain/usecases.dart';
import 'book_detail_state.dart';

class BookDetailVM extends StateNotifier<BookDetailState> {
  final GetBooks _getBooks;

  BookDetailVM(this._getBooks) : super(const BookDetailState()) {
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
