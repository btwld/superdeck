import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../../styling/styles.dart';

/// Immutable data holder for text elements in Hero animations
class TextElement {
  final String text;
  final TextSpec spec;
  final Size size;

  const TextElement({
    required this.text,
    required this.spec,
    required this.size,
  });
}

/// Immutable data holder for code elements in Hero animations
class CodeElement {
  final String text;
  final String language;
  final MarkdownCodeblockSpec spec;
  final Size size;

  const CodeElement({
    required this.text,
    required this.language,
    required this.spec,
    required this.size,
  });
}

/// Immutable data holder for image elements in Hero animations
class ImageElement {
  final ImageSpec spec;
  final Uri uri;
  final Size size;

  const ImageElement({
    required this.spec,
    required this.uri,
    required this.size,
  });
}

/// Generic InheritedWidget for providing element data to Hero animations.
///
/// This widget makes element-specific data available through the widget tree,
/// primarily for use in Hero `flightShuttleBuilder` callbacks where data from
/// both source and destination contexts needs to be accessed for smooth
/// interpolated transitions.
///
/// Usage in builders:
/// ```dart
/// return HeroElement(
///   data: TextElement(text: content, spec: spec, size: size),
///   child: widget,
/// );
/// ```
///
/// Usage in Hero flightShuttleBuilder:
/// ```dart
/// final to = HeroElement.of<TextElement>(toHeroContext);
/// final from = HeroElement.maybeOf<TextElement>(fromHeroContext);
/// ```
class HeroElement<T> extends InheritedWidget {
  final T data;

  const HeroElement({
    super.key,
    required super.child,
    required this.data,
  });

  @override
  bool updateShouldNotify(HeroElement<T> oldWidget) {
    return oldWidget.data != data;
  }

  /// Returns the data of type [T] from the closest [HeroElement] ancestor,
  /// or null if not found.
  static T? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HeroElement<T>>()?.data;
  }

  /// Returns the data of type [T] from the closest [HeroElement] ancestor.
  /// Throws if not found.
  static T of<T>(BuildContext context) {
    final result = maybeOf<T>(context);
    assert(result != null, 'No HeroElement<$T> found in context');
    return result!;
  }

}

/// Generic helper to build a Hero widget with custom flight animation.
///
/// This eliminates duplication across text/code/image element builders by
/// providing a single implementation of the Hero + flightShuttleBuilder pattern.
///
/// Usage:
/// ```dart
/// buildElementHero<TextElement>(
///   tag: 'myHero',
///   child: StyledText('content'),
///   buildFlight: (context, from, to, t) {
///     return StyledText(
///       lerpString(from.text, to.text, t),
///       styleSpec: StyleSpec(spec: from.spec.lerp(to.spec, t)),
///     );
///   },
/// )
/// ```
Widget buildElementHero<T>({
  required String tag,
  required Widget child,
  required Widget Function(BuildContext context, T from, T to, double t)
      buildFlight,
}) {
  return Hero(
    tag: tag,
    child: child,
    flightShuttleBuilder: (
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection flightDirection,
      BuildContext fromHeroContext,
      BuildContext toHeroContext,
    ) {
      final to = HeroElement.of<T>(toHeroContext);
      final from = HeroElement.maybeOf<T>(fromHeroContext) ?? to;

      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) => buildFlight(context, from, to, animation.value),
      );
    },
  );
}
