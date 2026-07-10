import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// A Mix context selector for a named widget-block container and subtree.
///
/// A block variant is active only while building a widget block whose resolved
/// name exactly matches [name].
final class BlockVariant extends ContextVariant {
  /// The widget block name this variant matches.
  final String name;

  const BlockVariant(this.name) : super('block_$name', _neverMatches);

  @override
  bool Function(BuildContext) get shouldApply => when;

  @override
  bool when(BuildContext context) {
    return BlockVariantScope.maybeOf(context)?.name == name;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BlockVariant && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

bool _neverMatches(BuildContext _) => false;

/// Provides the current named widget block to descendants.
///
/// This scope is used by SuperDeck's renderer. It is intentionally not
/// exported from the public package barrel.
class BlockVariantScope extends InheritedWidget {
  /// The resolved widget-block name for this subtree.
  final String name;

  const BlockVariantScope({
    super.key,
    required this.name,
    required super.child,
  });

  /// Returns the nearest block variant scope, if one is active.
  static BlockVariantScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BlockVariantScope>();
  }

  @override
  bool updateShouldNotify(BlockVariantScope oldWidget) {
    return name != oldWidget.name;
  }
}
