import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../common/helpers/provider.dart';
import 'deck_options.dart';
import 'slide_configuration.dart';

class DeckController with ChangeNotifier {
  DeckOptions options;
  List<SlideConfiguration> slides;
  PresentationRepository _dataStore;

  DeckController({
    required this.options,
    required this.slides,
    required PresentationRepository dataStore,
  }) : _dataStore = dataStore;

  void update({
    List<Slide>? slides,
    DeckOptions? options,
  }) {
    if (slides != null || options != null) {
      this.options = options ?? this.options;
      final newSlides =
          slides ?? this.slides.map((slide) => slide.data).toList();
      this.slides = _buildSlides(
        slides: newSlides,
        options: this.options,
        dataStore: _dataStore,
      );

      notifyListeners();
    }
  }

  factory DeckController.build({
    required List<Slide> slides,
    required DeckOptions options,
    required PresentationRepository dataStore,
  }) {
    return DeckController(
      options: options,
      slides: _buildSlides(
        slides: slides,
        options: options,
        dataStore: dataStore,
      ),
      dataStore: dataStore,
    );
  }

  static DeckController of(BuildContext context) {
    return InheritedNotifierData.of<DeckController>(context);
  }

  Map<String, Widget Function(Map<String, dynamic> props)> getSlideWidgets(
    BuildContext context,
    DeckOptions options,
  ) {
    final slideWidgets = <String, Widget Function(Map<String, dynamic> props)>{
      // Add default widgets here if any
    };

    // Use the slides from this controller, not from SlideConfiguration
    final slideConfigs = slides;

    // Find all CustomElement instances across all slides and sections
    final customElements = slideConfigs
        .expand((config) => config.sections)
        .expand((s) => s.blocks)
        .whereType<CustomElement>(); // Use the new type name

    // Register the widget builders found in options for the specific element IDs
    for (final element in customElements) {
      final widgetBuilder = options.widgets[element.id]; // Access by element.id
      if (widgetBuilder != null) {
        slideWidgets[element.id] = widgetBuilder; // Register using element.id
      }
    }
    // Add all widgets from options (potentially duplicates, but ensures all are included)
    slideWidgets.addAll(options.widgets);

    return slideWidgets;
  }
}

List<SlideConfiguration> _buildSlides({
  required List<Slide> slides,
  required DeckOptions options,
  required PresentationRepository dataStore,
}) {
  if (slides.isEmpty) {
    return [
      _convertSlide(
        slideIndex: 0,
        slide: _emptySlide,
        options: options,
        dataStore: dataStore,
      )
    ];
  }
  return slides.mapIndexed((index, slide) {
    return _convertSlide(
      slideIndex: index,
      slide: slide,
      options: options,
      dataStore: dataStore,
    );
  }).toList();
}

SlideConfiguration _convertSlide({
  required int slideIndex,
  required Slide slide,
  required DeckOptions options,
  required PresentationRepository dataStore,
}) {
  final customElements = slide.sections
      .expand((section) => section.blocks)
      .whereType<CustomElement>();

  final slideWidgets = <String, WidgetBlockBuilder>{};

  for (final element in customElements) {
    final widgetBuilder = options.widgets[element.id];
    if (widgetBuilder != null) {
      slideWidgets[element.id] = widgetBuilder;
    }
  }

  final styles = options.styles;
  final styleName = slide.options?.style;
  final baseStyle = options.baseStyle;
  final style = baseStyle.build().merge(styles[styleName]?.build());
  final thumbnailFile = dataStore.getAssetPath(
    Asset.thumbnail(slide.key),
  );
  return SlideConfiguration(
    slideIndex: slideIndex,
    style: style,
    slide: slide,
    debug: options.debug,
    parts: options.parts,
    widgets: slideWidgets,
    thumbnailFile: thumbnailFile,
  );
}

final _emptySlide = Slide(
  key: 'empty',
  sections: [
    SlideSection([
      '## No slides found'.markdown().alignCenter(),
      'Update the slides.md file to add slides to your deck.'
          .markdown()
          .alignBottomRight(),
    ]),
  ],
);
