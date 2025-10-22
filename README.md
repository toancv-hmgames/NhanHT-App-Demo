# story_reader_manifest_demo (v2)

- Uses a build-time `assets/books_manifest.json`
- Generator ensures RELATIVE asset keys like `assets/books/...`
- Tapping a chapter now shows a SnackBar and error page if the asset path is wrong

## Run
dart run tool/gen_books_manifest.dart
flutter pub get
flutter run