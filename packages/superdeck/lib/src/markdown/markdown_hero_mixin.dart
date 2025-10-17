import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../deck/slide_configuration.dart';
import '../ui/widgets/hero_element.dart';

/// Shared mixin that wraps markdown widgets with hero animations when a hero
/// tag is present on the parsed element.
mixin MarkdownHeroMixin on MarkdownElementBuilder {
  /// Applies hero animation wrapping if a hero tag is present and we're not
  /// exporting.
  Widget applyHeroIfNeeded<T>({
    required BuildContext context,
    required Widget child,
    required String? heroTag,
    required T heroData,
    required Widget Function(BuildContext, T, T, double) buildFlight,
  }) {
    final shouldAnimate =
        heroTag != null && !SlideConfiguration.of(context).isExporting;

    if (!shouldAnimate) return child;

    return HeroElement<T>(
      data: heroData,
      child: buildElementHero<T>(
        tag: heroTag,
        child: child,
        buildFlight: buildFlight,
      ),
    );
  }
}
