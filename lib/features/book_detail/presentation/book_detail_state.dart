import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/book.dart';
import '../../../core/domain/entities/chapter_summary.dart';

class BookDetailState {
  final AsyncValue<Book> book;
  final AsyncValue<List<ChapterSummary>> chapters;
  const BookDetailState({required this.book, required this.chapters});
}