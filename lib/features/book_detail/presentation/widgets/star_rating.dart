
import 'package:flutter/material.dart';

import '../../../../gen/colors.gen.dart';

class StarRating extends StatelessWidget {
  final int starCount;
  final double rating;
  final Color? color;
  const StarRating({
    super.key,
    this.starCount = 5,  // Default to 5 stars
    this.rating = 0.0,  // Default rating is 0
    this.color,  // Optional: custom color for stars
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        starCount,  // Generate a row with 'starCount' stars
            (final index) => _buildStar(context, index),
      ),
    );
  }

  // Method to build each individual star based on the rating and index
  Widget _buildStar(final BuildContext context, final int index) {
    Icon icon;
    // If the index is greater than or equal to the rating, we show an empty star
    if (index >= rating) {
      icon = const Icon(
        Icons.star_border,  // Empty star
        size: 20,
        color: ColorName.secondaryContainerGray,  // Light gray for empty stars
      );
    }
    // If the index is between the rating minus 1 and the rating, we show a half star
    else if (index > rating - 1 && index < rating) {
      icon = Icon(
        Icons.star_half,  // Half star
        size: 20,
        color: color ?? ColorName.ratingPrimaryColor,  // Default to gold color or custom color
      );
    }
    // Otherwise, we show a full star
    else {
      icon = Icon(
        Icons.star,  // Full star
        size: 20,
        color: color ?? ColorName.ratingPrimaryColor,  // Default to gold color or custom color
      );
    }
    return icon;
  }
}
