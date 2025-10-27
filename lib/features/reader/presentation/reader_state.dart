// lib/features/reader/presentation/reader_state.dart

import '../../../share/const_value.dart';

class ReaderChapterItem {
  final int chapterIdx;
  final String title;
  final String content;

  const ReaderChapterItem({
    required this.chapterIdx,
    required this.title,
    required this.content,
  });
}

class ReaderState {
  final String bookId;

  /// Các chương đã load, theo thứ tự hiển thị trong ListView
  /// Ví dụ: [ch3, ch4, ch5]
  final List<ReaderChapterItem> loadedChapters;

  /// Chỉ số chương đang active (ví dụ 4 nghĩa là chap 4 trong truyện)
  /// -> đây sẽ là chương gần đầu viewport, dùng để save progress
  final int activeChapterIdx;

  /// Tiêu đề (title) của chương active.
  /// Dùng để hiển thị ngay lập tức ở AppBar, không cần chờ load nội dung.
  final String activeChapterTitle;

  /// Offset (px) bên trong chương active tại thời điểm lưu
  /// => dùng để restore đúng dòng khi mở lại
  final double savedOffsetInActiveChapter;

  /// Đang init lần đầu chưa?
  final bool initLoading;

  /// Đang load thêm chương trước / sau?
  final bool isLoadingMorePrev;
  final bool isLoadingMoreNext;

  /// Lỗi gần nhất (nếu có)
  final Object? error;

  final bool isRestoring;

  final ReaderThemeMode themeMode;

  const ReaderState({
    required this.bookId,
    required this.loadedChapters,
    required this.activeChapterIdx,
    required this.activeChapterTitle,
    required this.savedOffsetInActiveChapter,
    required this.initLoading,
    required this.isLoadingMorePrev,
    required this.isLoadingMoreNext,
    required this.error,
    required this.isRestoring,
    required this.themeMode,
  });

  factory ReaderState.initial(String bookId) {
    return ReaderState(
      bookId: bookId,
      loadedChapters: const [],
      activeChapterIdx: 0,
      activeChapterTitle: '', // ban đầu rỗng, sẽ set rất sớm trong _init()
      savedOffsetInActiveChapter: 0,
      initLoading: true,
      isLoadingMorePrev: false,
      isLoadingMoreNext: false,
      error: null,
      isRestoring: true,
      themeMode: ReaderThemeMode.dark,
    );
  }

  ReaderState copyWith({
    List<ReaderChapterItem>? loadedChapters,
    int? activeChapterIdx,
    String? activeChapterTitle,
    double? savedOffsetInActiveChapter,
    bool? initLoading,
    bool? isLoadingMorePrev,
    bool? isLoadingMoreNext,
    Object? error,
    bool? isRestoring,
    ReaderThemeMode? themeMode,
  }) {
    return ReaderState(
      bookId: bookId,
      loadedChapters: loadedChapters ?? this.loadedChapters,
      activeChapterIdx: activeChapterIdx ?? this.activeChapterIdx,
      activeChapterTitle: activeChapterTitle ?? this.activeChapterTitle,
      savedOffsetInActiveChapter:
          savedOffsetInActiveChapter ?? this.savedOffsetInActiveChapter,
      initLoading: initLoading ?? this.initLoading,
      isLoadingMorePrev: isLoadingMorePrev ?? this.isLoadingMorePrev,
      isLoadingMoreNext: isLoadingMoreNext ?? this.isLoadingMoreNext,
      error: error ?? this.error,
      isRestoring: isRestoring ?? this.isRestoring,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
