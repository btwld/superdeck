import 'dart:io';

import 'package:ack/ack.dart';
import 'package:superdeck_core/src/utils/extensions.dart';
import 'package:test/test.dart';

void main() {
  group('Extensions', () {
    group('FileX', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('file_ext_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      group('ensureExists', () {
        test('creates file if it does not exist', () async {
          final file = File('${tempDir.path}/new_file.txt');
          expect(await file.exists(), isFalse);

          await file.ensureExists();

          expect(await file.exists(), isTrue);
        });

        test('returns the file instance', () async {
          final file = File('${tempDir.path}/return_test.txt');
          final result = await file.ensureExists();

          expect(result, same(file));
        });

        test('does nothing if file already exists', () async {
          final file = File('${tempDir.path}/existing.txt');
          await file.writeAsString('original content');

          await file.ensureExists();

          expect(await file.readAsString(), 'original content');
        });

        test('writes content when creating new file', () async {
          final file = File('${tempDir.path}/with_content.txt');

          await file.ensureExists(content: 'hello world');

          expect(await file.readAsString(), 'hello world');
        });

        test('does not overwrite existing file content', () async {
          final file = File('${tempDir.path}/no_overwrite.txt');
          await file.writeAsString('existing');

          await file.ensureExists(content: 'new content');

          expect(await file.readAsString(), 'existing');
        });

        test('creates parent directories recursively', () async {
          final file = File('${tempDir.path}/deep/nested/path/file.txt');
          expect(await file.exists(), isFalse);

          await file.ensureExists();

          expect(await file.exists(), isTrue);
        });

        test('handles empty content parameter', () async {
          final file = File('${tempDir.path}/empty_content.txt');

          await file.ensureExists(content: '');

          expect(await file.exists(), isTrue);
          expect(await file.readAsString(), '');
        });
      });

      group('ensureWrite', () {
        test('creates file and writes content', () async {
          final file = File('${tempDir.path}/write_new.txt');

          await file.ensureWrite('content');

          expect(await file.exists(), isTrue);
          expect(await file.readAsString(), 'content');
        });

        test('overwrites existing file content', () async {
          final file = File('${tempDir.path}/write_overwrite.txt');
          await file.writeAsString('old content');

          await file.ensureWrite('new content');

          expect(await file.readAsString(), 'new content');
        });

        test('creates parent directories recursively', () async {
          final file = File('${tempDir.path}/another/deep/path/file.txt');

          await file.ensureWrite('nested content');

          expect(await file.exists(), isTrue);
          expect(await file.readAsString(), 'nested content');
        });

        test('returns the file instance', () async {
          final file = File('${tempDir.path}/return_write.txt');
          final result = await file.ensureWrite('test');

          expect(result.path, file.path);
        });

        test('handles empty string content', () async {
          final file = File('${tempDir.path}/empty_write.txt');

          await file.ensureWrite('');

          expect(await file.readAsString(), '');
        });

        test('handles multiline content', () async {
          final file = File('${tempDir.path}/multiline.txt');
          const content = '''line1
line2
line3''';

          await file.ensureWrite(content);

          expect(await file.readAsString(), content);
        });

        test('handles special characters', () async {
          final file = File('${tempDir.path}/special.txt');
          const content = 'Unicode: 你好 🎉 émojis';

          await file.ensureWrite(content);

          expect(await file.readAsString(), content);
        });
      });
    });

    group('DirectoryX', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('dir_ext_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      group('ensureExists', () {
        test('creates directory if it does not exist', () async {
          final dir = Directory('${tempDir.path}/new_dir');
          expect(await dir.exists(), isFalse);

          await dir.ensureExists();

          expect(await dir.exists(), isTrue);
        });

        test('returns the directory instance when created', () async {
          final dir = Directory('${tempDir.path}/return_test');
          final result = await dir.ensureExists();

          expect(result.path, dir.path);
        });

        test('returns existing directory if it already exists', () async {
          final dir = Directory('${tempDir.path}/existing_dir');
          await dir.create();

          final result = await dir.ensureExists();

          expect(result, same(dir));
        });

        test('creates parent directories recursively', () async {
          final dir = Directory('${tempDir.path}/deep/nested/directory');
          expect(await dir.exists(), isFalse);

          await dir.ensureExists();

          expect(await dir.exists(), isTrue);
          expect(
            await Directory('${tempDir.path}/deep').exists(),
            isTrue,
          );
          expect(
            await Directory('${tempDir.path}/deep/nested').exists(),
            isTrue,
          );
        });
      });
    });

    group('ackEnum', () {
      test('converts simple enum names to snake_case', () {
        final schema = ackEnum(SimpleEnum.values);

        expect(schema.safeParse('one').isOk, isTrue);
        expect(schema.safeParse('two').isOk, isTrue);
        expect(schema.safeParse('three').isOk, isTrue);
      });

      test('converts camelCase enum names to snake_case', () {
        final schema = ackEnum(CamelCaseEnum.values);

        expect(schema.safeParse('first_value').isOk, isTrue);
        expect(schema.safeParse('second_value').isOk, isTrue);
        expect(schema.safeParse('third_value_here').isOk, isTrue);
      });

      test('handles single word enums', () {
        final schema = ackEnum(SingleWordEnum.values);

        expect(schema.safeParse('alpha').isOk, isTrue);
        expect(schema.safeParse('beta').isOk, isTrue);
      });

      test('rejects invalid enum values', () {
        final schema = ackEnum(SimpleEnum.values);

        expect(schema.safeParse('invalid').isOk, isFalse);
        expect(schema.safeParse('ONE').isOk, isFalse);
        expect(schema.safeParse('').isOk, isFalse);
      });

      test('handles uppercase abbreviations', () {
        final schema = ackEnum(AbbreviationEnum.values);

        // URLParser becomes url_parser
        expect(schema.safeParse('url_parser').isOk, isTrue);
        expect(schema.safeParse('html_element').isOk, isTrue);
      });

      test('handles numeric suffixes', () {
        final schema = ackEnum(NumericEnum.values);

        // Enum names stay as-is when they're single words with numbers
        expect(schema.safeParse('version1').isOk, isTrue);
        expect(schema.safeParse('version2').isOk, isTrue);
      });
    });

    group('HexColorValidation', () {
      group('valid hex colors', () {
        test('accepts 6-digit hex with # prefix', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#ff0000').isOk, isTrue);
          expect(schema.safeParse('#00ff00').isOk, isTrue);
          expect(schema.safeParse('#0000ff').isOk, isTrue);
          expect(schema.safeParse('#ffffff').isOk, isTrue);
          expect(schema.safeParse('#000000').isOk, isTrue);
        });

        test('accepts 6-digit hex without # prefix', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('ff0000').isOk, isTrue);
          expect(schema.safeParse('00ff00').isOk, isTrue);
          expect(schema.safeParse('abcdef').isOk, isTrue);
        });

        test('accepts 8-digit hex with alpha (ARGB)', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#80ff0000').isOk, isTrue);
          expect(schema.safeParse('#00ffffff').isOk, isTrue);
          expect(schema.safeParse('#ffffffff').isOk, isTrue);
        });

        test('accepts 8-digit hex without # prefix', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('80ff0000').isOk, isTrue);
          expect(schema.safeParse('ffaabbcc').isOk, isTrue);
        });

        test('accepts uppercase hex digits', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#FF0000').isOk, isTrue);
          expect(schema.safeParse('#AABBCC').isOk, isTrue);
          expect(schema.safeParse('FFAABBCC').isOk, isTrue);
        });

        test('accepts mixed case hex digits', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#FfAaBb').isOk, isTrue);
          expect(schema.safeParse('aAbBcCdD').isOk, isTrue);
        });
      });

      group('invalid hex colors', () {
        test('rejects 3-digit shorthand', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#f00').isOk, isFalse);
          expect(schema.safeParse('abc').isOk, isFalse);
        });

        test('rejects 4-digit shorthand with alpha', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#f00f').isOk, isFalse);
          expect(schema.safeParse('abcd').isOk, isFalse);
        });

        test('rejects wrong length hex', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#ff00').isOk, isFalse);
          expect(schema.safeParse('#ff00000').isOk, isFalse);
          expect(schema.safeParse('#ff0000000').isOk, isFalse);
          expect(schema.safeParse('ff').isOk, isFalse);
        });

        test('rejects non-hex characters', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#gggggg').isOk, isFalse);
          expect(schema.safeParse('#xyz123').isOk, isFalse);
          expect(schema.safeParse('#ff00gg').isOk, isFalse);
        });

        test('rejects empty string', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('').isOk, isFalse);
        });

        test('rejects only hash symbol', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('#').isOk, isFalse);
        });

        test('rejects color names', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('red').isOk, isFalse);
          expect(schema.safeParse('blue').isOk, isFalse);
        });

        test('rejects rgb() format', () {
          final schema = Ack.string().hexColor();

          expect(schema.safeParse('rgb(255, 0, 0)').isOk, isFalse);
        });
      });

    });
  });
}

// Test enums for ackEnum tests
enum SimpleEnum { one, two, three }

enum CamelCaseEnum { firstValue, secondValue, thirdValueHere }

enum SingleWordEnum { alpha, beta }

enum AbbreviationEnum { urlParser, htmlElement }

enum NumericEnum { version1, version2 }
