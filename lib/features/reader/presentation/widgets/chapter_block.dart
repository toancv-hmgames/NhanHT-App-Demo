import 'package:flutter/material.dart';

import '../../../../gen/colors.gen.dart';

class ChapterBlock extends StatelessWidget {
  final String title;
  final String content;
  final bool showHeader;

  final Color titleColor;
  final Color bodyColor;

  const ChapterBlock({
    required this.title,
    required this.content,
    required this.showHeader,
    required this.titleColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 16),
          Center(
              child: Text(
            "- End of chapter -",
            style: TextStyle(color: ColorName.bookTitleColor),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
