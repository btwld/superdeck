import 'package:flutter/widgets.dart';

/// Builds a widget from the raw arguments provided by a widget block.
///
/// The widget is inserted into the deck tree, so block and slide context stay
/// available from its `build` method.
typedef WidgetFactory = Widget Function(Map<String, Object?> args);
