import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

import '../common/helpers/provider.dart';
import 'deck_options.dart';
import 'slide_configuration.dart';

class DeckController with ChangeNotifier {
  DeckOptions options;
  List<SlideConfiguration> slides;
  IDataStore _dataStore;

  DeckController({
    required this.options,
    required this.slides,
    required IDataStore dataStore,
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
    required IDataStore dataStore,
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
}

List<SlideConfiguration> _buildSlides({
  required List<Slide> slides,
  required DeckOptions options,
  required IDataStore dataStore,
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
  required IDataStore dataStore,
}) {
  final widgetBlocks = slide.sections
      .expand((section) => section.blocks)
      .whereType<WidgetBlock>();

  final slideWidgets = <String, WidgetBlockBuilder>{};

  for (final block in widgetBlocks) {
    final widgetBuilder = options.widgets[block.name];
    if (widgetBuilder != null) {
      slideWidgets[block.name] = widgetBuilder;
    }
  }

  final styles = options.styles;
  final styleName = slide.options?.style;
  final baseStyle = options.baseStyle;
  final style = baseStyle.build().merge(styles[styleName]?.build());
  final thumbnailFile = dataStore.getGeneratedAssetPath(
    GeneratedAsset.thumbnail(slide.key),
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
    SectionBlock([
      '## No slides found'.column().alignCenter(),
      'Update the slides.md file to add slides to your deck.'
          .column()
          .alignBottomRight(),
    ]),
  ],
);
