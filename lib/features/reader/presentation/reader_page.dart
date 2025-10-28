import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gen/colors.gen.dart';
import '../../../core/di/providers.dart'; // <- có readerVMProvider(bookId)
import '../../../share/const_value.dart';
import 'reader_state.dart';
import 'reader_view_model.dart';
import 'widgets/chapter_block.dart';
import 'widgets/chapter_header.dart';
import 'widgets/measure_size.dart';
import 'widgets/reader_settings_sheet.dart';

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

    // ----- Trạng thái init / lỗi blocking -----
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

    // ----- Lỗi nặng (không load được gì) -----
    if (state.error != null && state.loadedChapters.isEmpty) {
      return Scaffold(
        backgroundColor: ColorName.background,
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

    // ----- Tiêu đề hiển thị trên top bar -----
    final appBarTitle = state.activeChapterTitle.isNotEmpty
        ? state.activeChapterTitle
        : (chapters.isNotEmpty ? chapters.first.title : 'Loading…');

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // NỘI DUNG ĐỌC
          Positioned.fill(
            child: Builder(
              builder: (context) {
                // Nếu đang init mà chưa có nội dung chương -> spinner body
                if (state.initLoading && chapters.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // GestureDetector để toggle hiện/ẩn chrome (top/bottom bars)
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    vm.toggleChrome();
                  },
                  child: ListView.builder(
                    controller: vm.scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    itemCount: chapters.length + 1,
                    itemBuilder: (context, index) {
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
                          // chỉ header khi KHÔNG phải chương đầu list
                          showHeader: index != 0,
                          titleColor: chapterTitleColor,
                          bodyColor: bodyTextColor,
                          fontPx: state.fontPx,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // TOP BAR ANIMATED
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _AnimatedTopBar(
              visible: state.uiChromeVisible,
              bgColor: bgColor,
              titleColor: titleColor,
              title: appBarTitle,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),

          // BOTTOM BAR ANIMATED
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _AnimatedBottomBar(
              visible: state.uiChromeVisible,
              bgColor: bgColor,
              onShowChapterList: _showChapterList,
              onToggleTheme: vm.toggleTheme,
              onShowReaderSettings: () {
                _showReaderSettingsSheet(
                  context: context,
                  bookId: widget.bookId,
                );
              },
            ),
          ),
        ],
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

  void _showReaderSettingsSheet({
    required BuildContext context,
    required String bookId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ReaderSettingsSheet(bookId: bookId);
      },
    );
  }
}

///
/// Thanh top bar trượt từ trên xuống + fade
///
class _AnimatedTopBar extends StatelessWidget {
  final bool visible;
  final Color bgColor;
  final Color titleColor;
  final String title;
  final VoidCallback onBack;

  const _AnimatedTopBar({
    required this.visible,
    required this.bgColor,
    required this.titleColor,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.only(
            top: 48, // chừa status bar + khoảng thở
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.92),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                ),
                color: titleColor,
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///
/// Thanh bottom bar trượt từ dưới lên + fade
///
class _AnimatedBottomBar extends StatelessWidget {
  final bool visible;
  final Color bgColor;
  final VoidCallback onShowChapterList;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowReaderSettings;

  const _AnimatedBottomBar({
    required this.visible,
    required this.bgColor,
    required this.onShowChapterList,
    required this.onToggleTheme,
    required this.onShowReaderSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: 12,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onShowChapterList,
                  icon: const Icon(Icons.list),
                ),
                IconButton(
                  onPressed: onToggleTheme,
                  icon: const Icon(Icons.sunny),
                ),
                IconButton(
                  onPressed: onShowReaderSettings,
                  icon: const Icon(Icons.text_format_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
