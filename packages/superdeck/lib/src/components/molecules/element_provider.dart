import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../modules/common/helpers/provider.dart';
import '../../modules/common/styles/style_spec.dart';

class ElementData<T extends SlideElement> {
  const ElementData({
    required this.block,
    required this.spec,
    required this.size,
  });

  final T block;
  final Size size;
  final SlideSpec spec;

  @override
  bool operator ==(Object other) {
    return other is ElementData &&
        other.spec == spec &&
        other.size == size &&
        other.block == block;
  }

  @override
  int get hashCode => spec.hashCode ^ size.hashCode ^ block.hashCode;

  static ElementData<T> of<T extends SlideElement>(BuildContext context) {
    final data = InheritedData.maybeOf<ElementData<T>>(context);
    if (data == null) {
      throw FlutterError(
          'ElementData<$T> not found in context. Make sure a SlideElementWidget is an ancestor.');
    }
    return data;
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
