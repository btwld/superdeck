import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

const _fixturePath =
    'packages/superdeck/test/integration/fixtures/authoring_deck.md';
const _builderPackagePath = 'packages/builder';
const _buildScriptSource = r'''
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

Future<void> main(List<String> args) async {
  final workspace = DeckWorkspace(projectDir: args.single);
  final store = DeckBuildStore(workspace: workspace);
  final builder = DeckBuilder(workspace: workspace, store: store);
  await builder.build();
}
''';

void main() {
  group('Authoring integration (build pipeline)', () {
    test(
      'plain markdown slide produces a single default section with one block',
      () async {
        final slides = await _buildFixtureDeck();
        final slide = slides[0];

        expect(slide.sections, hasLength(1));
        final section = slide.sections.single;
        expect(section.blocks, hasLength(1));
        final block = section.blocks.single;

        expect(block, isA<ContentBlock>());
        expect((block as ContentBlock).content, contains('# Plain Markdown'));
        expect(
          block.content,
          contains('This slide keeps regular markdown content together.'),
        );
        expect(block.content, contains('- List'));
      },
    );

    test('@section with multiple @block children produces expected section + '
        'block structure', () async {
      final slides = await _buildFixtureDeck();
      final slide = slides[1];

      expect(slide.sections, hasLength(1));
      final section = slide.sections.single;
      expect(section.type, SectionBlock.key);
      expect(section.blocks, hasLength(2));

      final leftBlock = section.blocks[0];
      final rightBlock = section.blocks[1];

      expect(leftBlock, isA<ContentBlock>());
      expect((leftBlock as ContentBlock).content, contains('## Left Column'));
      expect(leftBlock.content, contains('Author text in the first column.'));

      expect(rightBlock, isA<ContentBlock>());
      expect((rightBlock as ContentBlock).content, contains('## Right Column'));
      expect(rightBlock.content, contains('Author text in the second column.'));
    });

    test(
      '@block option (alignment) is parsed and preserved on the slide model',
      () async {
        final slides = await _buildFixtureDeck();
        final slide = slides[2];
        final block = slide.sections.single.blocks.single;

        expect(block, isA<ContentBlock>());
        expect(block.align, ContentAlignment.center);
        expect(
          (block as ContentBlock).content,
          contains('## Centered Callout'),
        );
      },
    );

    test(
      '@image widget block produces a WidgetBlock with expected args',
      () async {
        final slides = await _buildFixtureDeck();
        final slide = slides[3];
        final block = slide.sections.single.blocks.single;

        expect(block, isA<WidgetBlock>());
        expect(block.type, WidgetBlock.key);

        final widgetBlock = block as WidgetBlock;
        expect(widgetBlock.name, 'image');
        expect(
          widgetBlock.args,
          containsPair('src', 'assets/images/sample-diagram.png'),
        );
        expect(widgetBlock.args, containsPair('fit', 'cover'));
      },
    );

    test(
      'section and block layout options are preserved through the build',
      () async {
        final slides = await _buildFixtureDeck();
        final slide = slides[4];

        expect(slide.sections, hasLength(2));

        final topSection = slide.sections[0];
        final footerSection = slide.sections[1];
        expect(topSection.flex, 2);
        expect(footerSection.flex, 1);
        expect(topSection.blocks, hasLength(2));

        final narrowBlock = topSection.blocks[0] as ContentBlock;
        final wideBlock = topSection.blocks[1] as ContentBlock;
        final footerBlock = footerSection.blocks.single as ContentBlock;

        expect(narrowBlock.flex, 1);
        expect(narrowBlock.align, ContentAlignment.topLeft);
        expect(wideBlock.flex, 3);
        expect(wideBlock.scrollable, isTrue);
        expect(footerBlock.align, ContentAlignment.bottomRight);
      },
    );

    test(
      '@widget block keeps an explicit widget name and arbitrary args',
      () async {
        final slides = await _buildFixtureDeck();
        final block = slides[5].sections.single.blocks.single;

        expect(block, isA<WidgetBlock>());
        final widgetBlock = block as WidgetBlock;
        expect(widgetBlock.name, 'poll');
        expect(widgetBlock.args, containsPair('question', 'Ready to ship?'));
        expect(widgetBlock.args['choices'], orderedEquals(['yes', 'no']));
      },
    );

    test(
      'built-in widget shorthand tags become widget blocks with args',
      () async {
        final slides = await _buildFixtureDeck();
        final qrBlock = slides[6].sections.single.blocks.single as WidgetBlock;
        final dartPadBlock =
            slides[7].sections.single.blocks.single as WidgetBlock;

        expect(qrBlock.name, 'qrcode');
        expect(qrBlock.args, containsPair('text', 'https://superdeck.dev'));
        expect(qrBlock.args, containsPair('size', 180));
        expect(qrBlock.args, containsPair('errorCorrection', 'high'));

        expect(dartPadBlock.name, 'dartpad');
        expect(dartPadBlock.args, containsPair('id', 'abc123'));
        expect(dartPadBlock.args, containsPair('theme', 'dark'));
        expect(dartPadBlock.args, containsPair('embed', isTrue));
        expect(dartPadBlock.args, containsPair('run', isFalse));
      },
    );

    test('escaped directive syntax remains markdown content', () async {
      final slides = await _buildFixtureDeck();
      final block = slides[8].sections.single.blocks.single;

      expect(block, isA<ContentBlock>());
      expect(block.align, isNull);
      expect(
        (block as ContentBlock).content,
        contains('@block {align: center}'),
      );
    });

    test('total slide count matches fixture', () async {
      final slides = await _buildFixtureDeck();

      expect(slides, hasLength(9));
    });
  });
}

Future<List<Slide>> _buildFixtureDeck() async {
  final repoRoot = _repoRoot();
  final fixture = File(p.join(repoRoot.path, _fixturePath));
  final tempDir = _createTempDir(prefix: 'authoring_integration_');
  final workspace = _createTestWorkspace(tempDir);

  await workspace.slidesFile.writeAsString(await fixture.readAsString());
  await _runBuilder(repoRoot, workspace);

  final deckJson =
      jsonDecode(await workspace.deckJson.readAsString()) as List<dynamic>;

  return deckJson
      .map((entry) => Slide.parse(Map<String, Object?>.from(entry as Map)))
      .toList(growable: false);
}

Future<void> _runBuilder(Directory repoRoot, DeckWorkspace workspace) async {
  final builderDir = Directory(p.join(repoRoot.path, _builderPackagePath));
  final packageConfig = File(
    p.join(builderDir.path, '.dart_tool/package_config.json'),
  );
  final buildScript = File(
    p.join(workspace.projectDir, 'build_authoring_deck.dart'),
  );
  await buildScript.writeAsString(_buildScriptSource);

  final result = await Process.run(_dartExecutable(repoRoot), [
    '--packages=${packageConfig.path}',
    buildScript.path,
    workspace.projectDir,
  ], workingDirectory: builderDir.path);

  if (result.exitCode != 0) {
    fail(
      'DeckBuilder failed with exit code ${result.exitCode}\n'
      'stdout:\n${result.stdout}\n'
      'stderr:\n${result.stderr}',
    );
  }
}

Directory _createTempDir({String prefix = 'superdeck_authoring_'}) {
  final tempDir = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  return tempDir;
}

DeckWorkspace _createTestWorkspace(Directory tempDir) {
  return DeckWorkspace(projectDir: tempDir.path);
}

Directory _repoRoot() {
  var current = Directory.current;

  while (!File(p.join(current.path, 'melos.yaml')).existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      fail('Could not locate repository root from ${Directory.current.path}.');
    }
    current = parent;
  }

  return current;
}

String _dartExecutable(Directory repoRoot) {
  final fvmDart = File(p.join(repoRoot.path, '.fvm/flutter_sdk/bin/dart'));
  if (fvmDart.existsSync()) {
    return fvmDart.path;
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    return p.join(flutterRoot, 'bin/dart');
  }

  return 'dart';
}
