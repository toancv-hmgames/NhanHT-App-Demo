import 'package:flutter/material.dart';

class AnimatedTopBar extends StatelessWidget {
  final bool visible;
  final Color bgColor;
  final Color titleColor;
  final String title;
  final VoidCallback onBack;

  const AnimatedTopBar({
    super.key,
    required this.visible,
    required this.bgColor,
    required this.titleColor,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Container(
          height: kToolbarHeight +
              MediaQuery.of(context).padding.top, // AppBar mặc định
          color: bgColor, // ❌ bỏ opacity, để màu thật
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top, // status bar
            left: 16,
            right: 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: titleColor,
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
