import 'package:flutter/material.dart';

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
  late final GlobalKey _widgetKey;
  Size? _size;

  @override
  void initState() {
    super.initState();
    _widgetKey = GlobalKey(debugLabel: 'MeasureSize');
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    return Container(
      key: _widgetKey,
      child: widget.child,
    );
  }

  void _afterLayout(Duration timeStamp) {
    final context = _widgetKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (_size == renderBox?.size) return;
    if (renderBox != null && renderBox.hasSize) {
      _size = renderBox.size;
      widget.onChange(renderBox.size);
    }
  }
}
