import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_reading_app/gen/colors.gen.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/entities/book.dart';
import '../../discover/presentation/widgets/search_field.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryVMProvider);
    final vm = ref.watch(libraryVMProvider.notifier);

    final bgColor = ColorName.background;
    final textPrimary = ColorName.bookTitleColor; // màu chữ sáng đang dùng
    final textSecondary = ColorName.bookAuthorColor.withOpacity(0.8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: state.books.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Lỗi: $err',
                style: TextStyle(color: textPrimary),
              ),
            ),
            data: (allBooks) {
              // 1) lọc theo tab
              final filteredByTab = _filterByTab(
                allBooks,
                state.tabIndex,
              );

              // 2) lọc theo search
              final q = state.query.trim().toLowerCase();
              final display = q.isEmpty
                  ? filteredByTab
                  : filteredByTab.where((b) {
                      final title = b.title.toLowerCase();
                      final author = (b.author ?? '').toLowerCase();
                      return title.contains(q) || author.contains(q);
                    }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Top row: Tabs + actions ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabs
                      Expanded(
                        child: Row(
                          children: [
                            _LibraryTabButton(
                              label: 'Reading',
                              isActive: state.tabIndex == 0,
                              onTap: () => vm.setTab(0),
                              activeColor: textPrimary,
                              inactiveColor: textPrimary.withOpacity(0.5),
                            ),
                            const SizedBox(width: 16),
                            _LibraryTabButton(
                              label: 'Viewed',
                              isActive: state.tabIndex == 1,
                              onTap: () => vm.setTab(1),
                              activeColor: textPrimary,
                              inactiveColor: textPrimary.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),

                      // Actions on top right
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // Tuỳ bạn: có thể focus luôn search field bên dưới
                              // hoặc mở màn search riêng.
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // TODO: action của nút hồng
                            },
                            icon: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4B87),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Section title ---
                  Text(
                    'My Books',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Search field reuse từ Discover ---
                  // Ở Discover: SearchPill(hint, initial, onChanged, onClear)
                  SearchPill(
                    hint: "Search Books or Author...",
                    initial: state.query,
                    onChanged: vm.setQuery,
                    onClear: vm.clearQuery,
                  ),

                  const SizedBox(height: 24),

                  // --- List sách ---
                  Expanded(
                    child: display.isNotEmpty
                        ? ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: display.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, i) {
                              final book = display[i];
                              return _BookRowItem(
                                book: book,
                                titleColor: textPrimary,
                                authorColor: textSecondary,
                                onTap: () {
                                  // TODO: mở BookDetailPage(book.id)
                                  // Giống DiscoverPage -> Navigator.push(...)
                                },
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'No results found!',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Tách logic lọc theo tab:
  /// tab 0: Reading -> tạm thời trả allBooks (sau này bạn có thể filter theo "đang đọc")
  /// tab 1: Viewed  -> tạm thời cũng allBooks (sau này filter history)
  List<Book> _filterByTab(List<Book> all, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return all;
      case 1:
        return all;
      default:
        return all;
    }
  }
}

/// Nút tab trên cùng (Reading / Viewed)
class _LibraryTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _LibraryTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 1 item sách dạng hàng ngang
class _BookRowItem extends StatelessWidget {
  final Book book;
  final Color titleColor;
  final Color authorColor;
  final VoidCallback onTap;

  const _BookRowItem({
    required this.book,
    required this.titleColor,
    required this.authorColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverAsset = book.coverAsset;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // cover
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 52,
              height: 72,
              color: Colors.white12,
              child: Image.asset(
                coverAsset ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: Colors.white12,
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white54,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // meta (title + author)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: authorColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
