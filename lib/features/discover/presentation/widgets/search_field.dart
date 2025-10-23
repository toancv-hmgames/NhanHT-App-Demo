import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:story_reading_app/gen/colors.gen.dart';

import '../../../../gen/assets.gen.dart';

class SearchPill extends StatefulWidget {
  final String hint;
  final String initial;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchPill({
    super.key,
    required this.hint,
    required this.initial,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<SearchPill> createState() => SearchPillState();
}

class SearchPillState extends State<SearchPill> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant SearchPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = ColorName.searchFieldColor;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SvgPicture.asset(
            Assets.icons.search,
            width: 15,
            height: 15,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _c,
              onChanged: widget.onChanged,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white70,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  height: 1.0,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_c.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _c.clear();
                widget.onClear();
                setState(() {});
              },
              child: const Icon(Icons.close, size: 18, color: Colors.white60),
            ),
        ],
      ),
    );
  }
}
