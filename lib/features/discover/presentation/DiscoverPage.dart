import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../share/const_value.dart';
import 'widgets/book_tile.dart';
import 'widgets/search_field.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverVMProvider);
    final query = ref.watch(discoverSearchQueryProvider);
    final catIdx = ref.watch(discoverCategoryIndexProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: state.books.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi: $err')),
          data: (books) {
            final q = query.toLowerCase();
            final filtered = q.isEmpty
                ? books
                : books.where((b) {
                    final title = (b.title).toLowerCase();
                    final author = (b.author ?? '').toLowerCase();
                    return title.contains(q) || author.contains(q);
                  }).toList();

            final cat = categories[catIdx];
            final byCategory = filtered.where((b) => b.genres == cat).toList();

            if (filtered.isEmpty) {
              return const Center(child: Text('Không tìm thấy kết quả'));
            }

            return CustomScrollView(
              slivers: [
                // Search + gift icon
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        // pill
                        Expanded(
                          child: SearchPill(
                            hint: "Claimed by my Brother's Best Frie…",
                            initial: query,
                            onChanged: (text) => ref
                                .read(discoverSearchQueryProvider.notifier)
                                .state = text,
                            onClear: () => ref
                                .read(discoverSearchQueryProvider.notifier)
                                .state = '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {},
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          constraints: const BoxConstraints(minWidth: 40),
                          icon: Image.asset(
                            'assets/images/box_gift.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: List.generate(categories.length, (i) {
                          final selected = i == catIdx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => ref
                                  .read(discoverCategoryIndexProvider.notifier)
                                  .state = i,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    categories[i],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? AppColor.hotColor
                                          : Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 3,
                                    width: selected ? 18 : 0,
                                    decoration: BoxDecoration(
                                      color: AppColor.hotColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Grid sách
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      // card cover (3:4) + text → khoảng 1/0.68
                      mainAxisExtent: 320,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final b = filtered[index];
                        return BookTile(
                          book: b,
                          // onTap: () {
                          // },
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}
