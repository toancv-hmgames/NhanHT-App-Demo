import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
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
    // state đọc hiện tại (để biết chương đang active)
    final readerState = ref.watch(readerVMProvider(bookId));
    final vm = ref.read(readerVMProvider(bookId).notifier);

    // toàn bộ chapter metadata (FutureProvider)
    final chaptersAsync = ref.watch(chaptersMetaProvider(bookId));

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 250, // chỉnh tùy ý
          height: double.infinity,
          decoration: const BoxDecoration(
            color: ColorName.background,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                spreadRadius: 4,
                offset: Offset(4, 0),
                color: Colors.black26,
              )
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _HeaderBar(
                  bookId: readerState.bookId,
                  totalChaptersHint: chaptersAsync.maybeWhen(
                    data: (list) => '${list.length} Chapters',
                    orElse: () => 'Loading…',
                  ),
                  onClose: onClose,
                ),
                const Divider(height: 1),

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

                          return ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -1),
                            title: Text(
                              '${chMeta.idx + 1}. ${chMeta.title ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFE53935)
                                    : ColorName.bookTitleColor,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                            onTap: () async {
                              // đóng panel trước
                              onClose();

                              // nhảy thẳng tới chapter này như mở mới
                              await vm.openChapterAsRoot(chMeta.idx);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Lỗi load danh sách chương:\n$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
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
  final String totalChaptersHint;
  final VoidCallback onClose;

  const _HeaderBar({
    required this.bookId,
    required this.totalChaptersHint,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // giống header cũ nhưng gọn
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // thumbnail placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/books/$bookId/cover.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                // fallback nếu không có ảnh
                return Container(
                  width: 48,
                  height: 48,
                  color: ColorName.background,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 24,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // bookId + tổng chapter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // chưa có bookTitle trong ReaderState, nên tạm dùng bookId
                Text(
                  bookId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: ColorName.bookTitleColor,
                  ),
                ),
                Text(
                  totalChaptersHint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
