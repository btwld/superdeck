import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';
import '../ui/widgets/provider.dart';
import 'widget_factory.dart';

const _undefined = Object();

String buildThumbnailKey(String slideKey) {
  return 'thumbnail_$slideKey.png';
}

class SlideConfiguration {
  final int slideIndex;
  final SlideStyler style;
  final Slide slide;
  final bool debug;

  /// Whether untagged standalone images take automatic Hero positions.
  final bool animateImages;
  final SlideParts? parts;
  final Map<String, WidgetFactory> widgets;
  // Runtime thumbnail cache key (for example: thumbnail_intro.png).
  final String thumbnailKey;

  final bool isStaticRendering;

  /// Runtime asset cache used to resolve in-slide images referenced by a bare
  /// key (e.g. AI-generated images held in memory). Bound at build time by
  /// [SlideConfigurationBuilder]; resolved at render time by the image widgets.
  final AssetCacheStore? assetCacheStore;

  SlideConfiguration({
    required this.slideIndex,
    required this.style,
    required this.slide,
    this.debug = false,
    this.animateImages = true,
    this.parts,
    required this.thumbnailKey,
    this.widgets = const {},
    this.isStaticRendering = false,
    this.assetCacheStore,
  });

  SlideConfiguration copyWith({
    int? slideIndex,
    SlideStyler? style,
    Slide? slide,
    bool? debug,
    bool? animateImages,
    Object? parts = _undefined,
    Map<String, WidgetFactory>? widgets,
    String? thumbnailKey,
    bool? isStaticRendering,
    Object? assetCacheStore = _undefined,
  }) {
    return SlideConfiguration(
      slideIndex: slideIndex ?? this.slideIndex,
      style: style ?? this.style,
      slide: slide ?? this.slide,
      debug: debug ?? this.debug,
      animateImages: animateImages ?? this.animateImages,
      parts: identical(parts, _undefined) ? this.parts : parts as SlideParts?,
      widgets: widgets ?? this.widgets,
      thumbnailKey: thumbnailKey ?? this.thumbnailKey,
      isStaticRendering: isStaticRendering ?? this.isStaticRendering,
      assetCacheStore: identical(assetCacheStore, _undefined)
          ? this.assetCacheStore
          : assetCacheStore as AssetCacheStore?,
    );
  }

  SlideOptions get options => slide.options ?? SlideOptions();

  String get key => slide.key;

  List<SectionBlock> get sections => slide.sections;

  List<String> get comments => slide.comments;

  WidgetFactory? getWidgetFactory(String name) => widgets[name];

  static SlideConfiguration of(BuildContext context) {
    return InheritedData.of(context);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideConfiguration &&
          runtimeType == other.runtimeType &&
          slideIndex == other.slideIndex &&
          style == other.style &&
          slide == other.slide &&
          debug == other.debug &&
          animateImages == other.animateImages &&
          parts == other.parts &&
          thumbnailKey == other.thumbnailKey &&
          widgets == other.widgets &&
          isStaticRendering == other.isStaticRendering &&
          assetCacheStore == other.assetCacheStore;

  @override
  int get hashCode => Object.hash(
    slideIndex,
    style,
    slide,
    debug,
    animateImages,
    parts,
    thumbnailKey,
    widgets,
    isStaticRendering,
    assetCacheStore,
  );

  @override
  String toString() {
    return 'SlideConfiguration(slideIndex: $slideIndex, style: $style, '
        'slide: $slide, debug: $debug, animateImages: $animateImages, '
        'parts: $parts, widgets: $widgets, '
        'thumbnailKey: $thumbnailKey, isStaticRendering: $isStaticRendering, '
        'assetCacheStore: $assetCacheStore)';
  }
}
