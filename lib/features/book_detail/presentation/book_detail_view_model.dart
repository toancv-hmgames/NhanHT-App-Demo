import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show AsyncValue, StateNotifier;
import '../../../core/domain/entities/book.dart';
import '../../../core/domain/entities/chapter_summary.dart';
import '../../../core/domain/repositories/repositories.dart' as repo;

import 'book_detail_state.dart';

class BookDetailVM extends StateNotifier<BookDetailState> {
  BookDetailVM(this._repo)
      : super(const BookDetailState(
    book: AsyncValue.loading(),
    chapters: AsyncValue.loading(),
  ));

  final repo.CatalogRepository _repo;

  /// Load đầy đủ dữ liệu cho màn Book Detail theo bookId
  Future<void> load(String bookId) async {
    // đặt cả 2 nhánh về loading (hoặc bạn có thể giữ lại nhánh không thay đổi)
    state = BookDetailState(
      book: const AsyncValue.loading(),
      chapters: const AsyncValue.loading(),
    );

    try {
      // chạy song song 2 IO
      final results = await Future.wait([
        _repo.getBookById(bookId),
        _repo.listChapters(bookId),
      ]);

      final loadedBook = results[0] as Book;
      final loadedChapters = results[1] as List<ChapterSummary>;

      state = BookDetailState(
        book: AsyncValue.data(loadedBook),
        chapters: AsyncValue.data(loadedChapters),
      );
    } catch (e, st) {
      // gom lỗi vào đúng nhánh (ở đây mình cho cả 2 nhánh error để UI hiển thị dễ)
      state = BookDetailState(
        book: AsyncValue.error(e, st),
        chapters: AsyncValue.error(e, st),
      );
    }
  }

  /// Làm mới dữ liệu (gọi lại load với bookId hiện tại nếu đang có)
  Future<void> refresh(String bookId) async {
    // Có thể show loading nhẹ cho từng nhánh tuỳ ý
    state = BookDetailState(
      book: const AsyncValue.loading(),
      chapters: const AsyncValue.loading(),
    );
    await load(bookId);
  }
}
