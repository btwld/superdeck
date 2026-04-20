/// Flutter widgets and presentation components for SuperDeck.
library;

export 'src/capture/slide_capture_service.dart';
export 'src/rendering/slides/slide_constants.dart';
export 'src/rendering/slides/slide_parts.dart';
export 'src/rendering/slides/slide_render_view.dart';
export 'src/thumbnails/async_thumbnail.dart';
export 'src/thumbnails/thumbnail_service.dart';

// Utils
export 'src/ui/extensions.dart';

// Styling
export 'src/styling/default_style.dart';
export 'src/styling/components/markdown_alert.dart';
export 'src/styling/components/markdown_alert_type.dart';
export 'src/styling/components/markdown_blockquote.dart';
export 'src/styling/components/markdown_checkbox.dart';
export 'src/styling/components/markdown_codeblock.dart';
export 'src/styling/components/markdown_list.dart';
export 'src/styling/components/markdown_table.dart';
export 'src/styling/components/markdown_text.dart';
export 'src/styling/components/slide.dart';

// UI
export 'src/ui/superdeck_app.dart';

// Presentation
export 'src/deck/deck_controller.dart';
export 'src/deck/deck_options.dart';
export 'src/deck/loaders/bundled_deck_loader.dart';
export 'src/deck/loaders/file_deck_loader.dart';
export 'src/deck/slide_configuration.dart';
export 'src/deck/slide_template.dart';
export 'src/deck/template_exception.dart';
export 'src/deck/widget_factory.dart';

// Built-in Widgets
export 'src/builtins/dartpad_widget.dart';
export 'src/builtins/image_widget.dart';
export 'src/builtins/qr_code_widget.dart';
export 'src/builtins/widgets.dart';
