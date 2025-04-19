import 'package:superdeck_core/superdeck_core.dart' as core;

import 'model_adapters.dart';

/// Options for slides
class SlideOptions {
  final String? title;
  final String? subtitle;
  final Map<String, dynamic> _rawOptions;

  const SlideOptions({
    this.title,
    this.subtitle,
    Map<String, dynamic>? rawOptions,
  }) : _rawOptions = rawOptions ?? const {};

  /// Create from core SlideOptions or return default
  factory SlideOptions.parse(Map<String, dynamic>? options) {
    if (options == null) return const SlideOptions();

    return SlideOptions(
      title: options['title'] as String?,
      subtitle: options['subtitle'] as String?,
      rawOptions: options,
    );
  }

  /// Convert to a Map for use with core APIs
  Map<String, dynamic> toMap() => _rawOptions;
}

/// Slide model that adapts from core Slide
class Slide {
  final String key;
  final SlideOptions? options;
  final List<SlideSection> sections;
  final List<String> comments;

  const Slide({
    required this.key,
    this.options,
    required this.sections,
    required this.comments,
  });

  /// Create from core Slide
  factory Slide.fromCore(core.Slide slide) {
    final options = slide.options;

    return Slide(
      key: slide.key,
      options: options != null ? SlideOptions.parse(options.args) : null,
      sections: slide.sections.map((s) => SlideSection.fromBlock(s)).toList(),
      comments: slide.comments,
    );
  }

  /// Create a core Slide from this model
  core.Slide toCore() {
    return core.Slide(
      key: key,
      options: options != null
          ? core.SlideOptions(
              title: options!.title,
              args: options!.toMap(),
            )
          : null,
      sections: sections.map((s) => s as core.SectionBlock).toList(),
      comments: comments,
    );
  }

  /// Convert slide options to a Map that the core API expects
  Map<String, dynamic>? get optionsMap => options?.toMap();

  /// Method to support existing mapper code
  Slide copyWith({
    String? key,
    SlideOptions? options,
    List<SlideSection>? sections,
    List<String>? comments,
  }) {
    return Slide(
      key: key ?? this.key,
      options: options ?? this.options,
      sections: sections ?? this.sections,
      comments: comments ?? this.comments,
    );
  }
}
