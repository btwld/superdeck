import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:superdeck_core/markdown_json.dart';
import 'package:test/test.dart';

/// Generates `github_markdown_ref.json` from the showcase markdown document.
void main() {
  test('Generate GitHub Markdown showcase reference', () {
    final sourceFile =
        File('test/data/github_web_markdown_showcase.md');
    final markdown = sourceFile.readAsStringSync();

    final converter = MarkdownAstConverter(
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    final reference = <String, Object?>{
      'metadata': {
        'generated': DateTime.now().toIso8601String(),
        'markdown_package_version': '7.3.0',
        'extension_set': 'gitHubWeb',
        'source_file': sourceFile.path,
        'description':
            'AST reference generated from github_web_markdown_showcase.md',
      },
      'markdown': markdown,
      'ast': converter.toMap(
        markdown,
        includeMetadata: true,
      ),
    };

    final outputFile = File('github_markdown_ref.json');
    final newContent = const JsonEncoder.withIndent('  ').convert(reference);
    final shouldWrite =
        !outputFile.existsSync() || outputFile.readAsStringSync() != newContent;

    if (shouldWrite) {
      outputFile.writeAsStringSync(newContent);
      print('✅ Generated github_markdown_ref.json');
    } else {
      print('✓ github_markdown_ref.json is up to date');
    }
  });
}
