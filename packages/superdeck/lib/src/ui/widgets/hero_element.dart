import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../../styling/components/markdown_codeblock.dart';

/// Immutable data holder for text elements in Hero animations
class TextElement {
  final String text;
  final TextSpec spec;

  const TextElement({required this.text, required this.spec});
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

  /// Reuses an endpoint that cannot be reconstructed from [uri] and [spec],
  /// such as a resolved asset, decoded image, or scaled `@image` layout.
  final Widget? flightImage;

  const ImageElement({
    required this.spec,
    required this.uri,
    required this.size,
    this.flightImage,
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
///   data: TextElement(text: content, spec: spec),
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

  const HeroElement({super.key, required super.child, required this.data});

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

/// Generic helper to build a Hero widget with a custom flight shuttle.
///
/// This shares the Hero placeholder behavior across text, code, and image
/// element builders. The supplied shuttle builder owns its flight animation.
///
/// Usage:
/// ```dart
/// buildElementHero<TextElement>(
///   tag: 'myHero',
///   child: StyledText('content'),
///   flightShuttleBuilder: buildTextHeroFlight,
/// )
/// ```
Widget buildElementHero<T>({
  required String tag,
  required Widget child,
  required HeroFlightShuttleBuilder flightShuttleBuilder,
}) {
  return Hero(
    tag: tag,
    // A redirected page transition may rebuild the shuttle while either
    // endpoint is still in flight. Flutter's default destination placeholder
    // removes its child, leaving no paragraph for the shuttle to measure.
    // Keep endpoint layout available, without painting, hit testing, semantics,
    // or ticking its animations underneath the flying copy.
    placeholderBuilder: (context, size, child) => SizedBox.fromSize(
      size: size,
      child: Offstage(child: TickerMode(enabled: false, child: child)),
    ),
    flightShuttleBuilder: flightShuttleBuilder,
    child: child,
  );
}
