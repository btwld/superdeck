import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_builder/src/parsers/comment_parser.dart';
import 'package:superdeck_builder/src/parsers/markdown_parser.dart';
import 'package:superdeck_builder/src/parsers/section_parser.dart';
import 'package:superdeck_core/superdeck_core.dart';

Map<String, dynamic> _sanitizeSlideMap(Map<String, dynamic> map) {
  final sanitized = Map<String, dynamic>.from(map);
  sanitized['key'] = '<key>';
  return sanitized;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/generate_golden.dart <markdownPath>');
    exit(64);
  }
  final mdPath = args.first;
  final absPath = p.normalize(p.absolute(mdPath));
  final markdown = await File(absPath).readAsString();

  final rawSlides = const MarkdownParser().parse(markdown);
  final slides = rawSlides.map((raw) {
    return Slide(
      key: raw.key,
      options: SlideOptions.parse(raw.frontmatter),
      sections: const SectionParser().parse(raw.content),
      comments: const CommentParser().parse(raw.content),
    );
  }).toList();

  final jsonMap = {
    'slides': slides.map((s) => _sanitizeSlideMap(s.toMap())).toList(),
  };
  final pretty = const JsonEncoder.withIndent('  ').convert(jsonMap);
  stdout.writeln(pretty);
}
