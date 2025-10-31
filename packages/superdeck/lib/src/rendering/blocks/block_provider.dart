import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../ui/widgets/provider.dart';
import '../../styling/styles.dart';

class BlockConfiguration {
  const BlockConfiguration({
    required this.spec,
    required this.size,
    required this.align,
  });

  final SlideSpec spec;
  final Size size;
  final ContentAlignment? align;

  @override
  bool operator ==(Object other) {
    return other is BlockConfiguration &&
        other.spec == spec &&
        other.size == size &&
        other.align == align;
  }

  @override
  int get hashCode => spec.hashCode ^ size.hashCode ^ align.hashCode;

  static BlockConfiguration of(BuildContext context) {
    final data = InheritedData.maybeOf<BlockConfiguration>(context);
    if (data == null) {
      throw FlutterError('BlockConfiguration not found');
    }
    return data;
  }

  static BlockConfiguration? maybeOf(BuildContext context) {
    return InheritedData.maybeOf<BlockConfiguration>(context);
  }
}
