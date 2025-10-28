import 'package:flutter/material.dart';

class AnimatedBottomBar extends StatelessWidget {
  final bool visible;
  final Color bgColor;

  final VoidCallback onShowChapterList;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowReaderSettings;

  const AnimatedBottomBar({
    super.key,
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
          // tạo cảm giác như 1 bottom bar nổi từ mép dưới
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
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
