// Delegate cho SliverPersistentHeader (pinned Categories)
import 'package:flutter/material.dart';

class CategoriesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const CategoriesHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 50;
  @override
  double get minExtent => 50;
  @override
  bool shouldRebuild(covariant CategoriesHeaderDelegate oldDelegate) => true;
}
