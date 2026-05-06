import '../deck/widget_factory.dart';
import 'dartpad_widget.dart';
import 'image_widget.dart';
import 'qr_code_widget.dart';

/// Map of built-in widget factories.
///
/// These widgets are automatically available in all presentations:
/// - `image`: Display images with various fit options
/// - `dartpad`: Embed DartPad code editors
/// - `qrcode`: Generate QR codes
///
/// Built-in widgets are registered by default but can be overridden
/// by user-provided widgets with the same name.
final Map<String, WidgetFactory> builtInWidgets = {
  'image': ImageWidget.new,
  'dartpad': DartPadWidget.new,
  'qrcode': QrCodeWidget.new,
};
