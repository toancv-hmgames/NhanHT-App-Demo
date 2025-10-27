import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_reading_app/gen/colors.gen.dart';
import '../../../core/di/providers.dart';
import '../../../gen/assets.gen.dart';
import '../../../share/const_value.dart';
import '../../book_detail/presentation/book_detail_page.dart';
import 'widgets/book_tile.dart';
import 'widgets/categories_header_delegate.dart';
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

            // --- Lọc theo search ---
            final filtered = q.isEmpty
                ? books
                : books.where((b) {
              final title = (b.title).toLowerCase();
              final author = (b.author ?? '').toLowerCase();
              return title.contains(q) || author.contains(q);
            }).toList();

            // --- Lọc theo category ---
            String _norm(String s) =>
                s.toLowerCase().replaceAll(RegExp(AppConsts.normalValue), ' ').trim();

            final selectedCat = AppConsts.categories[catIdx];
            final display = filtered.where((b) {
              if (_norm(selectedCat) == _norm('Hot')) return true;
              final cats = (b.genres).map(_norm).toList();
              return cats.contains(_norm(selectedCat));
            }).toList();

            final screenWidth = MediaQuery.sizeOf(context).width;
            final tileWidth =
                (screenWidth - horizontalPadding * 2 - crossAxisSpacing) / 2;
            final tileHeight = tileWidth +
                coverGap +
                titleFontSize * lineHeight * titleLines +
                4 +
                authorFontSize * lineHeight * authorLines +
                spacingBelow;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // 🔹 AppBar chứa SearchBar — ẩn/hiện khi cuộn
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: ColorName.background,
                  elevation: innerBoxIsScrolled ? 1 : 0,
                  floating: true,
                  snap: true,
                  pinned: false, // AppBar không dính — sẽ ẩn/hiện
                  expandedHeight: 55,
                  flexibleSpace: Padding(
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
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔸 Categories bar — luôn pinned
                SliverPersistentHeader(
                  pinned: true,
                  delegate: CategoriesHeaderDelegate(
                    child: Container(
                      color: ColorName.background,
                      height: 50,
                      child: _buildCategoriesBar(
                        context,
                        catIdx,
                            (i) => ref
                            .read(discoverCategoryIndexProvider.notifier)
                            .state = i,
                      ),
                    ),
                  ),
                ),
              ],
              // 📚 Nội dung grid
              body: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: display.isNotEmpty
                    ? GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 0,
                    mainAxisExtent: tileHeight,
                  ),
                  itemCount: display.length,
                  itemBuilder: (context, index) {
                    final book = display[index];
                    return BookTile(
                      book: book,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BookDetailPage(bookId: book.id),
                          ),
                        );
                      },
                    );
                  },
                )
                    : const Center(child: Text('No results found!')),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesBar(
      BuildContext context, int catIdx, ValueChanged<int> onTap) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(AppConsts.categories.length, (i) {
          final selected = i == catIdx;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => onTap(i),
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
    );
  }
}

