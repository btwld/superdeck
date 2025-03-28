import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ZeroPaddingBuilder extends MarkdownPaddingBuilder {
  @override
  EdgeInsets getPadding() => EdgeInsets.zero;
}
