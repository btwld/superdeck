import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../modules/common/helpers/provider.dart';
import '../../modules/common/styles/style_spec.dart';

class BlockData<T extends Block> {
  const BlockData({
    required this.spec,
    required this.size,
    required this.block,
  });

  final SlideSpec spec;
  final Size size;
  final T block;

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
    final data = _tryAnyBlockData(context);
    if (data == null) {
      throw FlutterError('BlockData not found');
    }
    return data;
  }

  static BlockData<T>? inheritedData<T extends Block>(BuildContext context) {
    return InheritedData.maybeOf<BlockData<T>>(context);
  }

  static BlockData? _tryAnyBlockData(BuildContext context) {
    return inheritedData<ColumnBlock>(context) ??
        inheritedData<WidgetBlock>(context) ??
        inheritedData<ImageBlock>(context) ??
        inheritedData<DartPadBlock>(context);
  }
}

class SectionData {
  const SectionData({
    required this.section,
    required this.size,
  });

  final SectionBlock section;
  final Size size;

  @override
  bool operator ==(Object other) {
    return other is SectionData &&
        other.section == section &&
        other.size == size;
  }

  @override
  int get hashCode => section.hashCode ^ size.hashCode;
}
