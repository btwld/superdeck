import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_mermaid/superdeck_mermaid.dart';
import 'package:test/test.dart';

void main() {
  group('MermaidBuildPlugin', () {
    late Directory tempDir;
    late DeckWorkspace workspace;
    late DeckBuildContext context;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('mermaid_plugin_test_');
      workspace = DeckWorkspace(projectDir: tempDir.path);
      context = DeckBuildContext(
        workspace: workspace,
        slideKey: 'mermaid-test',
        slideIndex: 0,
        sectionIndex: 0,
        blockIndex: 0,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('replaces mermaid fenced code blocks with image markdown', () async {
      final generator = _FakeMermaidGenerator();
      final plugin = MermaidBuildPlugin(generator: generator);

      final block = await plugin.transformContentBlock(
        ContentBlock('Before\n\n```mermaid\ngraph TD\nA --> B\n```\n\nAfter'),
        context,
      );

      expect(block.content, contains('Before'));
      expect(block.content, contains('After'));
      expect(block.content, contains('![Mermaid diagram](.superdeck/mermaid/'));
      expect(block.content, isNot(contains('```mermaid')));
      expect(generator.renderCount, 1);
      expect(generator.sources.single, 'graph TD\nA --> B');

      final imagePath = _extractImagePath(block.content);
      expect(File(p.join(tempDir.path, imagePath)).existsSync(), isTrue);
    });

    test('leaves non-mermaid fenced code blocks unchanged', () async {
      final generator = _FakeMermaidGenerator();
      final plugin = MermaidBuildPlugin(generator: generator);
      const content = '```dart\nvoid main() {}\n```';

      final block = await plugin.transformContentBlock(
        ContentBlock(content),
        context,
      );

      expect(block.content, content);
      expect(generator.renderCount, 0);
    });

    test(
      'reuses cached image for unchanged source and configuration',
      () async {
        final generator = _FakeMermaidGenerator();
        final plugin = MermaidBuildPlugin(generator: generator);
        final block = ContentBlock('```mermaid\ngraph TD\nA --> B\n```');

        final first = await plugin.transformContentBlock(block, context);
        final second = await plugin.transformContentBlock(block, context);

        expect(
          _extractImagePath(first.content),
          _extractImagePath(second.content),
        );
        expect(generator.renderCount, 1);
      },
    );

    test('rerenders empty cached image files', () async {
      final generator = _FakeMermaidGenerator();
      final plugin = MermaidBuildPlugin(generator: generator);
      final block = ContentBlock('```mermaid\ngraph TD\nA --> B\n```');

      final first = await plugin.transformContentBlock(block, context);
      final imageFile = File(
        p.join(tempDir.path, _extractImagePath(first.content)),
      );
      await imageFile.writeAsBytes(const []);

      await plugin.transformContentBlock(block, context);

      expect(generator.renderCount, 2);
      expect(await imageFile.length(), greaterThan(0));
    });

    test('uses workspace output directory in generated asset paths', () async {
      final generator = _FakeMermaidGenerator();
      final workspace = DeckWorkspace(
        projectDir: tempDir.path,
        outputDir: 'generated',
      );
      final context = DeckBuildContext(
        workspace: workspace,
        slideKey: 'custom-output-dir',
        slideIndex: 0,
        sectionIndex: 0,
        blockIndex: 0,
      );
      final plugin = MermaidBuildPlugin(generator: generator);

      final block = await plugin.transformContentBlock(
        ContentBlock('```mermaid\ngraph TD\nA --> B\n```'),
        context,
      );

      expect(block.content, contains('](generated/mermaid/'));
    });

    test('changing configuration generates a different cached image', () async {
      final source = ContentBlock('```mermaid\ngraph TD\nA --> B\n```');
      final first = await MermaidBuildPlugin(
        generator: _FakeMermaidGenerator(),
      ).transformContentBlock(source, context);
      final second = await MermaidBuildPlugin(
        generator: _FakeMermaidGenerator(
          configuration: const {'theme': 'forest'},
        ),
      ).transformContentBlock(source, context);

      expect(
        _extractImagePath(first.content),
        isNot(_extractImagePath(second.content)),
      );
    });

    test('uses stable source-sensitive sha256 cache filenames', () async {
      final generator = _FakeMermaidGenerator();
      final plugin = MermaidBuildPlugin(generator: generator);
      final firstSource = ContentBlock('```mermaid\ngraph TD\nA --> B\n```');
      final secondSource = ContentBlock('```mermaid\ngraph TD\nA --> C\n```');

      final first = await plugin.transformContentBlock(firstSource, context);
      final sameFirst = await plugin.transformContentBlock(
        firstSource,
        context,
      );
      final second = await plugin.transformContentBlock(secondSource, context);

      final firstImagePath = _extractImagePath(first.content);
      expect(firstImagePath, _extractImagePath(sameFirst.content));
      expect(firstImagePath, isNot(_extractImagePath(second.content)));
      expect(
        p.posix.basename(firstImagePath),
        matches(RegExp(r'^mermaid_[a-f0-9]{64}\.png$')),
      );
      expect(generator.renderCount, 2);
    });

    test(
      'uses constructor configuration for owned generator cache keys',
      () async {
        const syntax = 'graph TD\nA --> B';
        const configuration = {'theme': 'forest'};
        final generator = MermaidGenerator(configuration: configuration);
        final expectedHash = _cacheKey(syntax, generator.configuration);
        await generator.dispose();

        final imageFile = context.outputFile(
          p.posix.join('mermaid', 'mermaid_$expectedHash.png'),
        );
        await imageFile.parent.create(recursive: true);
        await imageFile.writeAsBytes(const [1, 2, 3]);

        final plugin = MermaidBuildPlugin(configuration: configuration);
        addTearDown(plugin.dispose);

        final block = await plugin.transformContentBlock(
          ContentBlock('```mermaid\n$syntax\n```'),
          context,
        );

        expect(block.content, contains('mermaid_$expectedHash.png'));
      },
    );

    test('rejects configuration when a custom generator is provided', () {
      expect(
        () => MermaidBuildPlugin(
          configuration: const {'theme': 'forest'},
          generator: _FakeMermaidGenerator(),
        ),
        throwsArgumentError,
      );
    });

    test('renderer errors fail the transform', () async {
      final plugin = MermaidBuildPlugin(generator: _FailingMermaidGenerator());

      await expectLater(
        () => plugin.transformContentBlock(
          ContentBlock('```mermaid\ngraph TD\nA --> B\n```'),
          context,
        ),
        throwsA(isA<DeckFormatException>()),
      );
    });

    test('disposes a custom generator', () async {
      final generator = _FakeMermaidGenerator();
      final plugin = MermaidBuildPlugin(generator: generator);

      await plugin.dispose();

      expect(generator.disposeCount, 1);
    });
  });
}

String _extractImagePath(String content) {
  final match = RegExp(r'!\[Mermaid diagram\]\(([^)]+)\)').firstMatch(content);

  return match!.group(1)!;
}

String _cacheKey(String syntax, Map<String, Object?> configuration) {
  final payload = jsonEncode({
    'source': syntax,
    'configuration': _canonicalize(configuration),
  });

  return sha256.convert(utf8.encode(payload)).toString();
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries =
        value.entries
            .map((entry) => (key: entry.key.toString(), value: entry.value))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return {for (final entry in entries) entry.key: _canonicalize(entry.value)};
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }

  return value;
}

class _FakeMermaidGenerator extends MermaidGenerator {
  _FakeMermaidGenerator({super.configuration});

  final List<String> sources = [];
  int renderCount = 0;
  int disposeCount = 0;

  @override
  Future<Uint8List> render(String syntax) async {
    sources.add(syntax);
    renderCount++;

    return Uint8List.fromList(<int>[1, 2, 3, renderCount]);
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

class _FailingMermaidGenerator extends MermaidGenerator {
  @override
  Future<Uint8List> render(String syntax) async {
    throw StateError('Invalid diagram');
  }
}
