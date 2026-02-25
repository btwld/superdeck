import 'package:ack_annotations/ack_annotations.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'raw_slide_schema.g.dart';

@AckType()
final rawSlideFrontmatterSchema = Ack.object({}).passthrough();

@AckType()
final rawSlideMarkdownSchema = Ack.object({
  'key': Ack.string(),
  'content': Ack.string(),
  'frontmatter': rawSlideFrontmatterSchema,
});

typedef RawSlideMarkdown = RawSlideMarkdownType;
