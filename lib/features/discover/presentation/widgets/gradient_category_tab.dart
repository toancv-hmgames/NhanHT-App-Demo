import 'package:flutter/material.dart';

class GradientCategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final double fontSize;
  final FontWeight fontWeight;
  final double underlineExtra; // phần tràn ra ngoài text
  final double underlineHeight;
  final Gradient gradient;
  final Color unselectedColor;

  const GradientCategoryTab({
    super.key,
    required this.label,
    required this.selected,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.underlineExtra = 8,      // tràn nhẹ 2–4px mỗi bên
    this.underlineHeight = 2,     // mỏng 2px
    this.gradient = const LinearGradient(
      colors: [Color(0xFFF32222), Color(0xFFF38422)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    this.unselectedColor = const Color(0xFFFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    // Đo chiều rộng của text
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final textWidth = tp.width;

    final textWidget = selected
        ? ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    )
        : Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: unselectedColor.withOpacity(0.8),
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start, // 👈 căn trái
      children: [
        textWidget,
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: selected ? underlineHeight : 0,
          width: selected ? (textWidth + underlineExtra) : 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: selected ? gradient : null,
          ),
        ),
      ],
    );
  }
}
