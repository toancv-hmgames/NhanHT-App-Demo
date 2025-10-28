import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../share/const_value.dart';
import '../reader_view_model.dart';
import '../../../../gen/colors.gen.dart';

class ChaptersHeader extends ConsumerWidget {
  final String bookId;
  final VoidCallback onClose;

  const ChaptersHeader({
    super.key,
    required this.bookId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // state đọc hiện tại
    final readerState = ref.watch(readerVMProvider(bookId));
    final vm = ref.read(readerVMProvider(bookId).notifier);

    // theme động
    final isDark = readerState.themeMode == ReaderThemeMode.dark;

    final Color panelBg = isDark ? ColorName.background : Colors.white;
    final Color textPrimary =
        isDark ? ColorName.bookTitleColor : const Color(0xFF000000);
    final Color textSecondary =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);
    final Color activeColor =
        isDark ? const Color(0xFFFF6B6B) : const Color(0xFFE53935);
    final Color shadowColor = isDark ? Colors.black54 : Colors.black26;
    final Color thumbBg =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0);
    final Color thumbIcon = isDark ? const Color(0xFFBDBDBD) : Colors.grey;

    // list chapter metadata
    final chaptersAsync = ref.watch(chaptersMetaProvider(bookId));

    // book title để hiển thị ở header card
    // Nếu ReaderState chưa có title, bạn có thể thay bằng provider khác.
    final bookTitle = readerState.activeChapterTitle.trim().isNotEmpty == true
        ? readerState.activeChapterTitle.trim()
        : readerState.bookId; // fallback

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          height: double.infinity,
          decoration: BoxDecoration(
            color: panelBg,
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                spreadRadius: 4,
                offset: const Offset(4, 0),
                color: shadowColor,
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 8),

                // HEADER CARD
                _HeaderBar(
                  bookId: readerState.bookId,
                  bookTitle: bookTitle,
                  totalChaptersHint: chaptersAsync.maybeWhen(
                    data: (list) => '${list.length} Chapters',
                    orElse: () => 'Loading…',
                  ),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  thumbBg: thumbBg,
                  thumbIcon: thumbIcon,
                ),

                const SizedBox(height: 12),

                // body list
                Expanded(
                  child: chaptersAsync.when(
                    data: (allChapters) {
                      final activeIdx = readerState.activeChapterIdx;

                      return ListView.builder(
                        itemCount: allChapters.length,
                        itemBuilder: (context, idx) {
                          final chMeta = allChapters[idx];
                          final isActive = (chMeta.idx == activeIdx);

                          final Color lineColor =
                              isActive ? activeColor : textPrimary;
                          final FontWeight weight =
                              isActive ? FontWeight.w600 : FontWeight.normal;

                          return InkWell(
                            onTap: () async {
                              onClose(); // đóng panel
                              await vm.openChapterAsRoot(chMeta.idx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                '${chMeta.idx + 1}. ${chMeta.title ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: lineColor,
                                  fontWeight: weight,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(textPrimary),
                        ),
                      ),
                    ),
                    error: (err, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Lỗi load danh sách chương:\n$err',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String bookId;
  final String bookTitle;
  final String totalChaptersHint;

  final Color textPrimary;
  final Color textSecondary;
  final Color thumbBg;
  final Color thumbIcon;

  const _HeaderBar({
    required this.bookId,
    required this.bookTitle,
    required this.totalChaptersHint,
    required this.textPrimary,
    required this.textSecondary,
    required this.thumbBg,
    required this.thumbIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        // 🔹 container full width, không còn Align hay IntrinsicWidth
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.withOpacity(0.15),
        ),
        child: Row(
          // 🔹 bỏ mainAxisSize: min để row giãn theo chiều ngang
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // cover
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 40,
                height: 40,
                color: thumbBg,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/books/$bookId/cover.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    return Icon(
                      Icons.menu_book_outlined,
                      size: 20,
                      color: thumbIcon,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 10),

            // title + chapters
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    totalChaptersHint,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
