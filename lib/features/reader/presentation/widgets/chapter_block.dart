import 'package:flutter/material.dart';
import '../../../../gen/colors.gen.dart';

class ChapterBlock extends StatelessWidget {
  final String title;
  final String content;
  final bool showHeader;

  final Color titleColor;
  final Color bodyColor;

  // 👇 thêm tham số động
  final double fontPx;

  const ChapterBlock({
    super.key,
    required this.title,
    required this.content,
    required this.showHeader,
    required this.titleColor,
    required this.bodyColor,
    required this.fontPx,
  });

  @override
  Widget build(BuildContext context) {
    // body text size = user setting
    final double bodySize = fontPx;
    // header text size = body + 2 (có thể đổi +4 nếu bạn muốn header rõ hơn)
    final double headerSize = fontPx + 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: headerSize,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // nội dung chương
          Text(
            content,
            style: TextStyle(
              fontSize: bodySize,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: bodyColor,
            ),
          ),

          const SizedBox(height: 16),

          // end marker
          Center(
            child: Text(
              "- End of chapter -",
              style: TextStyle(
                fontSize: bodySize * 0.8, // hơi nhỏ hơn nội dung
                height: 1.4,
                fontWeight: FontWeight.w400,
                color: ColorName.bookTitleColor,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
