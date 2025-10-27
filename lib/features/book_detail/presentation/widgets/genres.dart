
import 'package:flutter/material.dart';

class Genres extends StatelessWidget {
  final List<String> genres;
  const Genres({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: genres.map((g) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.white, width: 1.4),
            borderRadius: BorderRadius.circular(999), // pill
          ),
          child: Text(
            g,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              height: 1.0,
              color: Colors.white
            ),
          ),
        );
      }).toList(),
    );
  }
}
