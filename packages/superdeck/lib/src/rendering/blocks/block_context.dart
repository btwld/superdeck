import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../ui/widgets/provider.dart';
import '../../styling/styling.dart';

class BlockContext {
  const BlockContext({
    required this.spec,
    required this.size,
    required this.align,
  });

  final SlideSpec spec;
  final Size size;
  final ContentAlignment? align;

  @override
  bool operator ==(Object other) {
    return other is BlockContext &&
        other.spec == spec &&
        other.size == size &&
        other.align == align;
  }

  @override
  int get hashCode => spec.hashCode ^ size.hashCode ^ align.hashCode;

  static BlockContext of(BuildContext context) {
    final data = InheritedData.maybeOf<BlockContext>(context);
    if (data == null) {
      throw FlutterError('BlockContext not found');
    }
    return data;
  }

  static BlockContext? maybeOf(BuildContext context) {
    return InheritedData.maybeOf<BlockContext>(context);
  }
}
