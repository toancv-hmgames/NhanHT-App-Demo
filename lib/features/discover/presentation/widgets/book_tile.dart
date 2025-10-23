import 'package:flutter/material.dart';

import '../../../../core/domain/entities/book.dart';

class BookTile extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookTile({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      color: Color(0xFFF5F5FA),
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.0,
      letterSpacing: 0,
    );
    final authorStyle = TextStyle(
      color: Color(0xFFEBEBF5),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
    );

    final coverAsset = book.coverAsset;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: w,
              height: w, // 👈 vuông
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  coverAsset ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu_book, color: Colors.white54),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(height: w * 0.35, child: _Meta(titleStyle, authorStyle)),
          ],
        );
      }),
    );
  }
  Widget _Meta(TextStyle title, TextStyle author) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: title),
        const SizedBox(height: 4),
        Text(book.author ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: author),
      ],
    );
  }
}

