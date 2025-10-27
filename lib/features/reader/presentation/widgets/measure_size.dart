import 'package:flutter/widgets.dart';

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required this.child,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder giúp mình bắt được constraints và trigger mỗi lần layout lại
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifySize();
        });
        return widget.child;
      },
    );
  }

  void _notifySize() {
    // Nếu widget này đã bị dispose khỏi tree (không mounted) thì bỏ qua
    if (!mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;
    if (!renderObject.attached) return;

    final newSize = renderObject.size;
    if (_oldSize == newSize) return;

    _oldSize = newSize;
    widget.onChange(newSize);
  }
}
