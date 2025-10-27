import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:story_reading_app/gen/assets.gen.dart';
import 'package:story_reading_app/gen/colors.gen.dart';
import '../../../core/di/providers.dart';
import '../../../share/const_value.dart';
import '../../reader/presentation/reader_page.dart';
import 'widgets/genres.dart';
import 'widgets/star_rating.dart';

class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookDetailVMProvider(bookId));
    final vm = ref.read(bookDetailVMProvider(bookId).notifier);

    //UI
    final screenWidth = MediaQuery.sizeOf(context).width;
    final totalHorizontal = (AppConsts.basePadding + AppConsts.extraInset) * 2; // 100

// kích thước ảnh vuông, luôn trừ đúng 100 và không vượt quá 320
    final imageSize = (screenWidth - totalHorizontal).clamp(0.0, AppConsts.maxImage);

    return Scaffold(
      backgroundColor: ColorName.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 25),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        backgroundColor: ColorName.background,
        title: state.book.when(
          error: (err, _) => Center(child: Text('Lỗi: $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
          data: (book) => Text(
            book.title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorName.bookTitleColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
        // : button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 30),
            child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                )),
          )
        ],
      ),
      body: state.book.when(
          error: (err, _) => Center(child: Text('Lỗi: $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
          data: (book) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          //cover
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              book.coverAsset ?? '',
                              fit: BoxFit.cover,
                              width: imageSize.toDouble(),
                              height: imageSize.toDouble(),
                            ),
                          ),

                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    //title
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    //author
                    Text(
                      book.author ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: ColorName.bookAuthorColor,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        StarRating(rating: 4.5, color: ColorName.ratingPrimaryColor),
                        const SizedBox(width: 12),
                        Text(
                          '${book.rating}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                              letterSpacing: 0,
                              color: ColorName.bookRatingColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Genres(genres: book.genres),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 53,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReaderPage(bookId: book.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorName.readBookButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                Assets.icons.library,
                                height: 20,
                                width: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Read Book',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                    letterSpacing: 0),
                              ),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${book.summary}',
                      style: TextStyle(
                        color: ColorName.bookTitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
