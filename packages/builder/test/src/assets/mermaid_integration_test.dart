import 'dart:io';

import 'package:superdeck_builder/src/assets/mermaid_generator.dart';
import 'package:superdeck_builder/src/assets/mermaid_theme.dart';
import 'package:test/test.dart';

/// Integration tests that actually generate PNG files
/// Run with: dart test test/src/assets/mermaid_integration_test.dart
void main() {
  group('MermaidGenerator Integration Tests', () {
    late Directory testOutputDir;
    late MermaidGenerator generator;

    setUp(() {
      // Create test output directory in /tmp
      testOutputDir = Directory('/tmp/superdeck_mermaid_test_${DateTime.now().millisecondsSinceEpoch}');
      testOutputDir.createSync(recursive: true);

      generator = MermaidGenerator(theme: MermaidTheme.dark);

      print('\n📁 Test output directory: ${testOutputDir.path}');
    });

    tearDown(() async {
      await generator.dispose();
      // Keep the output directory for manual inspection
      print('✓ Test output preserved at: ${testOutputDir.path}');
    });

    test('generates valid PNG for simple flowchart', () async {
      const diagram = '''
flowchart LR
    A[Start] --> B[Process]
    B --> C[End]
''';

      final outputPath = '${testOutputDir.path}/flowchart_valid.png';
      final pngBytes = await generator.generateAsset(diagram, outputPath);

      // Validate PNG was generated
      expect(pngBytes, isNotEmpty);
      expect(pngBytes.length, greaterThan(100)); // Reasonable minimum size

      // Write to file for manual inspection
      await File(outputPath).writeAsBytes(pngBytes);
      expect(await File(outputPath).exists(), isTrue);

      print('✓ Generated valid flowchart: $outputPath (${pngBytes.length} bytes)');
    });

    test('generates valid PNG for sequence diagram', () async {
      const diagram = '''
sequenceDiagram
    Alice->>Bob: Hello Bob!
    Bob-->>Alice: Hello Alice!
''';

      final outputPath = '${testOutputDir.path}/sequence_valid.png';
      final pngBytes = await generator.generateAsset(diagram, outputPath);

      expect(pngBytes, isNotEmpty);
      expect(pngBytes.length, greaterThan(100));

      await File(outputPath).writeAsBytes(pngBytes);
      expect(await File(outputPath).exists(), isTrue);

      print('✓ Generated valid sequence diagram: $outputPath (${pngBytes.length} bytes)');
    });

    test('generates valid PNG for pie chart', () async {
      const diagram = '''
pie title Test Distribution
    "Pass" : 80
    "Fail" : 15
    "Skip" : 5
''';

      final outputPath = '${testOutputDir.path}/pie_valid.png';
      final pngBytes = await generator.generateAsset(diagram, outputPath);

      expect(pngBytes, isNotEmpty);
      expect(pngBytes.length, greaterThan(100));

      await File(outputPath).writeAsBytes(pngBytes);
      expect(await File(outputPath).exists(), isTrue);

      print('✓ Generated valid pie chart: $outputPath (${pngBytes.length} bytes)');
    });

    test('throws clear error for invalid syntax', () async {
      // Use clearly invalid Mermaid syntax that will definitely fail
      const invalidDiagram = '''
this is not valid mermaid syntax at all
random text that will cause an error
''';

      final outputPath = '${testOutputDir.path}/flowchart_invalid.png';

      Exception? caughtException;
      try {
        await generator.generateAsset(invalidDiagram, outputPath);
      } catch (e) {
        caughtException = e as Exception;
        print('✓ Caught expected error: ${e.toString().split('\n').first}');
      }

      // Verify an exception was thrown
      expect(caughtException, isNotNull, reason: 'Should have thrown an exception for invalid syntax');

      // Verify error message is descriptive
      expect(caughtException.toString(), contains('Mermaid'));
      expect(caughtException.toString(), anyOf([
        contains('syntax'),
        contains('Syntax'),
        contains('error'),
        contains('Diagram'),
      ]));

      // Verify NO file was created for invalid diagram
      expect(await File(outputPath).exists(), isFalse);
    });

    test('handles complex state diagram', () async {
      const diagram = '''
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing
    Processing --> Success
    Processing --> Error
    Success --> [*]
    Error --> Idle
''';

      final outputPath = '${testOutputDir.path}/state_valid.png';
      final pngBytes = await generator.generateAsset(diagram, outputPath);

      expect(pngBytes, isNotEmpty);
      await File(outputPath).writeAsBytes(pngBytes);

      print('✓ Generated complex state diagram: $outputPath (${pngBytes.length} bytes)');
    });

    test('PNG files have valid PNG header', () async {
      const diagram = 'flowchart LR\n    A --> B';
      final outputPath = '${testOutputDir.path}/header_check.png';
      final pngBytes = await generator.generateAsset(diagram, outputPath);

      // PNG magic number: 89 50 4E 47 0D 0A 1A 0A
      expect(pngBytes[0], equals(0x89));
      expect(pngBytes[1], equals(0x50)); // 'P'
      expect(pngBytes[2], equals(0x4E)); // 'N'
      expect(pngBytes[3], equals(0x47)); // 'G'

      await File(outputPath).writeAsBytes(pngBytes);
      print('✓ PNG header validation passed');
    });
  });

  print('\n' + '='*80);
  print('Integration tests complete!');
  print('Check /tmp/superdeck_mermaid_test_* directories for generated images');
  print('='*80 + '\n');
}
