import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../styling/components/slide.dart';
import '../../ui/widgets/provider.dart';

/// Stable identity for a block within a slide tree.
///
/// Used as the default WebView cache key so remounts of the same block reuse
/// a controller without sharing across unrelated blocks by URL alone.
String buildBlockRuntimeKey(String slideKey, int sectionIndex, int blockIndex) {
  return '$slideKey:s$sectionIndex:b$blockIndex';
}

class BlockConfiguration {
  const BlockConfiguration({
    required this.spec,
    required this.size,
    required this.align,
    required this.runtimeKey,
  });

  final SlideSpec spec;
  final Size size;
  final ContentAlignment align;

  /// Slide-local identity derived from slide key + section/block indices.
  final String runtimeKey;

  @override
  bool operator ==(Object other) {
    return other is BlockConfiguration &&
        other.spec == spec &&
        other.size == size &&
        other.align == align &&
        other.runtimeKey == runtimeKey;
  }

  @override
  int get hashCode => Object.hash(spec, size, align, runtimeKey);

  static BlockConfiguration of(BuildContext context) {
    final data = InheritedData.maybeOf<BlockConfiguration>(context);
    if (data == null) {
      throw FlutterError('BlockConfiguration not found');
    }
    return data;
  }

  // ignore: unused-code
  static BlockConfiguration? maybeOf(BuildContext context) {
    return InheritedData.maybeOf<BlockConfiguration>(context);
  }
}
