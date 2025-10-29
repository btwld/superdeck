import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../ui/widgets/provider.dart';
import '../../styling/styles.dart';

class BlockData {
  const BlockData({
    required this.spec,
    required this.size,
    required this.block,
  });

  final SlideSpec spec;
  final Size size;
  final Block block;

  @override
  bool operator ==(Object other) {
    return other is BlockData &&
        other.spec == spec &&
        other.size == size &&
        other.block == block;
  }

  @override
  int get hashCode => spec.hashCode ^ size.hashCode ^ block.hashCode;

  static BlockData of(BuildContext context) {
    final data = InheritedData.maybeOf<BlockData>(context);
    if (data == null) {
      throw FlutterError('BlockData not found');
    }
    return data;
  }

  static BlockData? maybeOf(BuildContext context) {
    return InheritedData.maybeOf<BlockData>(context);
  }
}
