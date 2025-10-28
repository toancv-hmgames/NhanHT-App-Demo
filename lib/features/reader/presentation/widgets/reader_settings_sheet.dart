import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../share/const_value.dart';
import '../../../../core/di/providers.dart'; // để lấy readerVMProvider(bookId)

class ReaderSettingsSheet extends ConsumerWidget {
  final String bookId;

  const ReaderSettingsSheet({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerState = ref.watch(readerVMProvider(bookId));
    final vm = ref.read(readerVMProvider(bookId).notifier);

    final isDark = readerState.themeMode == ReaderThemeMode.dark;
    final fontPx = readerState.fontPx;
    final readingMode = readerState.readingMode;

    final bgCard = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF6B6B6B);

    final chipBg = const Color(0xFF4B4B6A);
    final chipText = Colors.white;

    final inactiveBg = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.05);
    final activeBg = const Color(0xFF4B4B6A);
    final inactiveText = isDark ? Colors.white60 : Colors.black54;
    final activeText = Colors.white;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, -8),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Font Size row ---
            Text(
              'Font Size',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // A-
                _PillButton(
                  label: 'A-',
                  bgColor: chipBg,
                  textColor: chipText,
                  onTap: vm.decreaseFont,
                ),

                const SizedBox(width: 20),

                // current font size number -> đọc trực tiếp từ provider
                Text(
                  fontPx.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),

                const SizedBox(width: 20),

                // A+
                _PillButton(
                  label: 'A+',
                  bgColor: chipBg,
                  textColor: chipText,
                  onTap: vm.increaseFont,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Reading Mode row ---
            Text(
              'Reading Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Slide',
                    isActive: readingMode == ReaderReadingMode.slide,
                    activeBg: activeBg,
                    inactiveBg: inactiveBg,
                    activeText: activeText,
                    inactiveText: inactiveText,
                    onTap: () => vm.setReadingMode(ReaderReadingMode.slide),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeButton(
                    label: 'Scroll',
                    isActive: readingMode == ReaderReadingMode.scroll,
                    activeBg: activeBg,
                    inactiveBg: inactiveBg,
                    activeText: activeText,
                    inactiveText: inactiveText,
                    onTap: () => vm.setReadingMode(ReaderReadingMode.scroll),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeBg;
  final Color inactiveBg;
  final Color activeText;
  final Color inactiveText;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.activeBg,
    required this.inactiveBg,
    required this.activeText,
    required this.inactiveText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? activeBg : inactiveBg;
    final txt = isActive ? activeText : inactiveText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: txt,
          ),
        ),
      ),
    );
  }
}
