// lib/features/reader/presentation/reader_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gen/colors.gen.dart';
import '../../../core/di/providers.dart'; // <- có readerVMProvider(bookId)
import '../../../share/const_value.dart';
import 'reader_view_model.dart';
import 'widgets/chapter_block.dart';
import 'widgets/chapter_header.dart';
import 'widgets/measure_size.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  ReaderVM? _vm;

  @override
  void initState() {
    super.initState();
    // Sau frame đầu tiên của trang ReaderPage, thử restore scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm?.tryRestoreScrollIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy VM & state từ Riverpod
    final vm = ref.watch(readerVMProvider(widget.bookId).notifier);
    _vm ??= vm;

    final state = ref.watch(readerVMProvider(widget.bookId));

    // ----- Trạng thái init / lỗi -----
    // initLoading = true lúc VM mới khởi tạo và đang load nội dung chương đầu tiên.
    // Lưu ý: ReaderVM giờ đã set sớm activeChapterTitle
    // nên ta vẫn muốn Scaffold và AppBar render được ngay cả khi initLoading.
    // => nghĩa là ta KHÔNG return CircularProgressIndicator toàn màn nếu còn initLoading,
    //    trừ khi thậm chí chưa có activeChapterTitle nào để show.
    final isInitialBlocking =
        state.initLoading && state.activeChapterTitle.isEmpty;

    if (isInitialBlocking) {
      // Trường hợp rất sớm: chưa có gì để hiển thị
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = state.themeMode == ReaderThemeMode.dark;

    final bgColor = isDark ? ColorName.background : Colors.white;
    final titleColor = isDark ? ColorName.bookTitleColor : Colors.black87;
    final chapterTitleColor = isDark ? ColorName.bookTitleColor : Colors.black;
    final bodyTextColor = isDark ? ColorName.bookTitleColor : Colors.black87;

    if (state.error != null && state.loadedChapters.isEmpty) {
      // Lỗi nặng, không có chapter nào load được
      return Scaffold(
        backgroundColor: ColorName.background,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: true,
          backgroundColor: bgColor,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: ColorName.bookTitleColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Text(
            'Error',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Lỗi: ${state.error}',
            style: TextStyle(color: titleColor),
          ),
        ),
      );
    }

    // ----- Dữ liệu chapters -----
    final chapters = state.loadedChapters;

    // ----- Tiêu đề AppBar -----
    // Trước đây bạn lấy từ chapter đang ở gần top (tìm trong chapters).
    // Bây giờ dùng thẳng state.activeChapterTitle.
    // Vì VM đã set activeChapterTitle rất sớm,
    // AppBar sẽ hiển thị ngay lập tức thay vì đợi loadChapterText.
    final appBarTitle = state.activeChapterTitle.isNotEmpty
        ? state.activeChapterTitle
        : (chapters.isNotEmpty ? chapters.first.title : 'Loading…');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: true,
        backgroundColor: bgColor,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: titleColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          // Trường hợp đang init nhưng đã có title, nhưng nội dung chưa load xong:
          // -> hiển thị spinner ở body thay vì che trắng cả màn.
          if (state.initLoading && chapters.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Render list chương dạng "cuộn dọc vô hạn"
          return ListView.builder(
            controller: vm.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            itemCount: chapters.length +
                1, // thêm 1 slot cuối để show dấu hiệu "đang load next"
            itemBuilder: (context, index) {
              // Nếu là phần tử extra cuối danh sách -> hiển thị loading more next
              final isExtraTail = index == chapters.length;
              if (isExtraTail) {
                if (state.isLoadingMoreNext) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }

              final ch = chapters[index];

              return MeasureSize(
                onChange: (size) {
                  if (size != null) {
                    vm.reportChapterLayout(
                      chapterIdx: ch.chapterIdx,
                      heightPx: size.height,
                    );
                  }
                },
                child: ChapterBlock(
                  title: ch.title,
                  content: ch.content,
                  // Với UX đọc liên tục: header chỉ cần hiện cho chương KHÔNG phải chương đầu list.
                  showHeader: index != 0,
                  titleColor: chapterTitleColor,
                  bodyColor: bodyTextColor,
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColor,
        elevation: 0,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const SizedBox(width: 24),
          IconButton(
            onPressed: _showChapterList,
            icon: const Icon(Icons.list),
          ),
          IconButton(
            onPressed: vm.toggleTheme,
            icon: const Icon(Icons.sunny),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.text_format_rounded),
          ),
          const SizedBox(width: 24),
        ]),
      ),
    );
  }

  void _showChapterList() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      pageBuilder: (context, anim1, anim2) {
        // không dùng pageBuilder body vì mình sẽ custom trong transitionBuilder
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final offset = Tween<Offset>(
          begin: const Offset(-1.0, 0.0), // bắt đầu ngoài bên trái
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          ),
        );

        return Stack(
          children: [
            // lớp nền tối phía sau panel, bấm để đóng
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black54.withOpacity(anim.value * 0.6),
              ),
            ),

            // panel trượt ngang
            SlideTransition(
              position: offset,
              child: ChaptersHeader(
                bookId: widget.bookId,
                onClose: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
