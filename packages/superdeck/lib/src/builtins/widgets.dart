import '../deck/widget_factory.dart';
import 'dartpad_widget.dart';
import 'image_widget.dart';
import 'qr_code_widget.dart';
import 'webview_widget.dart';

/// Map of built-in widget factories.
///
/// These widgets are automatically available in all presentations:
/// - `image`: Display images with various fit options
/// - `dartpad`: Embed DartPad code editors
/// - `webview`: Embed a persistent web page
/// - `qrcode`: Generate QR codes
///
/// Built-in widgets are registered by default but can be overridden
/// by user-provided widgets with the same name.
final builtInWidgets = <String, WidgetFactory>{
  'image': ImageWidget.new,
  'dartpad': DartPadWidget.new,
  'webview': WebViewWidget.new,
  'qrcode': QrCodeWidget.new,
};
