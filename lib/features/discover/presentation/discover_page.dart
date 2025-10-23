import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_reading_app/gen/colors.gen.dart';
import '../../../core/di/providers.dart';
import '../../../gen/assets.gen.dart';
import '../../../share/const_value.dart';
import 'widgets/book_tile.dart';
import 'widgets/gradient_category_tab.dart';
import 'widgets/search_field.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverVMProvider);
    final query = ref.watch(discoverSearchQueryProvider);
    final catIdx = ref.watch(discoverCategoryIndexProvider);

    return Scaffold(
      backgroundColor: ColorName.background,
      body: SafeArea(
        child: state.books.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi: $err')),
          data: (books) {
            final q = query.toLowerCase();

            // 1) Lọc theo text
            final filtered = q.isEmpty
                ? books
                : books.where((b) {
                    final title = (b.title).toLowerCase();
                    final author = (b.author ?? '').toLowerCase();
                    return title.contains(q) || author.contains(q);
                  }).toList();

            // Chuẩn hoá chuỗi để so sánh: bỏ khoảng trắng thừa, ký tự đặc biệt, về lowercase
            String _norm(String s) =>
                s.toLowerCase().replaceAll(RegExp(AppConsts.normalValue), ' ').trim();

            final selectedCat = AppConsts.categories[catIdx];
            final display = filtered.where((b) {
              // Nếu muốn "Hot" = hiển thị tất cả:
              if (_norm(selectedCat) == _norm('Hot')) return true;

              final cats = (b.genres ?? []).map(_norm).toList();
              return cats.contains(_norm(selectedCat));
            }).toList();

            return CustomScrollView(
              slivers: [
                // --- Search + gift: giữ nguyên ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
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
                          icon: Assets.images.boxGift.image(
                              width: 24, height: 24, fit: BoxFit.contain),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Categories
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children:
                            List.generate(AppConsts.categories.length, (i) {
                          final selected = i == catIdx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => ref
                                  .read(discoverCategoryIndexProvider.notifier)
                                  .state = i,
                              child: GradientCategoryTab(
                                label: AppConsts.categories[i],
                                selected: selected,
                                fontSize: 16,
                                underlineExtra: 14,
                                underlineHeight: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // --- Nếu có sách: render Grid ---
                if (display.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 0,      // khoảng cách giữa hàng
                        crossAxisSpacing: 16,     // khoảng cách giữa cột
                        childAspectRatio: 0.71,   // tỉ lệ width/height cho mỗi BookTile
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => BookTile(book: display[index]),
                        childCount: display.length,
                      ),
                    ),
                  )

                // --- Nếu không có sách: show placeholder trong scroll ---
                else
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No results found!'),
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
