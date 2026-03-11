import '../deck/widget_definition.dart';
import 'dartpad_widget.dart';
import 'image_widget.dart';
import 'qr_code_widget.dart';

export 'dartpad_widget.dart';
export 'image_widget.dart';
export 'qr_code_widget.dart';

/// Map of built-in widget definitions.
///
/// These widgets are automatically available in all presentations:
/// - `image`: Display images with various fit options
/// - `dartpad`: Embed DartPad code editors
/// - `qrcode`: Generate QR codes
///
/// Built-in widgets are registered by default but can be overridden
/// by user-provided widgets with the same name.
const Map<String, WidgetDefinition> builtInWidgets = {
  'image': ImageWidget(),
  'dartpad': DartPadWidget(),
  'qrcode': QrCodeWidget(),
};
