import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart' as core;

import '../common/helpers/provider.dart';
import '../models/model_adapters.dart' hide WidgetBlockBuilder;
import '../models/slide_model.dart';
import 'deck_options.dart';
import 'slide_configuration.dart';

class DeckController with ChangeNotifier {
  DeckOptions options;
  List<SlideConfiguration> slides;
  core.PresentationRepository _dataStore;

  DeckController({
    required this.options,
    required this.slides,
    required core.PresentationRepository dataStore,
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
    required core.PresentationRepository dataStore,
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
        .whereType<CustomElement>();

    // Register the widget builders found in options for the specific element IDs
    for (final element in customElements) {
      final widgetBuilder = options.widgets[element.id];
      if (widgetBuilder != null) {
        slideWidgets[element.id] = widgetBuilder;
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
  required core.PresentationRepository dataStore,
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
  required core.PresentationRepository dataStore,
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
  final styleName = slide.options?.title;
  final baseStyle = options.baseStyle;
  final style = baseStyle.build().merge(styles[styleName]?.build());
  final thumbnailFile = dataStore.getAssetPath(
    core.Asset.thumbnail(slide.key),
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

// Create a utility extension for String to markdown
extension StringMarkdownExtension on String {
  MarkdownElement markdown() {
    return MarkdownElement(
      type: 'markdown',
      content: this,
    );
  }
}

// Create a utility extension for SlideElement
extension SlideElementExtension on SlideElement {
  SlideElement alignCenter() {
    return copyWith(align: core.ContentAlignment.center);
  }

  SlideElement alignBottomRight() {
    return copyWith(align: core.ContentAlignment.bottomRight);
  }

  SlideElement copyWith({
    String? type,
    core.ContentAlignment? align,
    int? flex,
    bool? scrollable,
  }) {
    if (this is MarkdownElement) {
      final markdown = this as MarkdownElement;
      return MarkdownElement(
        type: type ?? markdown.type,
        content: markdown.content,
        align: align ?? markdown.align,
        flex: flex ?? markdown.flex,
        scrollable: scrollable ?? markdown.scrollable,
      );
    } else if (this is ImageElement) {
      final image = this as ImageElement;
      return ImageElement(
        type: type ?? image.type,
        asset: image.asset,
        fit: image.fit,
        width: image.width,
        height: image.height,
        align: align ?? image.align,
        flex: flex ?? image.flex,
        scrollable: scrollable ?? image.scrollable,
      );
    } else if (this is CustomElement) {
      final custom = this as CustomElement;
      return CustomElement(
        id: custom.id,
        type: type ?? custom.type,
        props: custom.props,
        align: align ?? custom.align,
        flex: flex ?? custom.flex,
        scrollable: scrollable ?? custom.scrollable,
      );
    } else {
      // Return this as is if type is unknown
      return this;
    }
  }
}

final _emptySlide = Slide(
  key: 'empty',
  sections: [
    SlideSection(
      type: 'section',
      blocks: [
        MarkdownElement(
          type: 'markdown',
          content: '## No slides found',
          align: core.ContentAlignment.center,
        ),
        MarkdownElement(
          type: 'markdown',
          content: 'Update the slides.md file to add slides to your deck.',
          align: core.ContentAlignment.bottomRight,
        ),
      ],
    ),
  ],
  comments: [],
);
