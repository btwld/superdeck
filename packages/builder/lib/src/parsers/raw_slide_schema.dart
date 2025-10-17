import 'package:ack_annotations/ack_annotations.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'raw_slide_schema.g.dart';

@AckType()
final rawSlideMarkdownSchema = Ack.object({
  'key': Ack.string(),
  'content': Ack.string(),
  'frontmatter': Ack.object({}).passthrough(),
});

typedef RawSlideMarkdown = RawSlideMarkdownType;
