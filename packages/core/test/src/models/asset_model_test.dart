import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('AssetExtension', () {
    group('tryParse', () {
      test('parses png extension', () {
        expect(AssetExtension.tryParse('png'), AssetExtension.png);
      });

      test('parses jpeg extension', () {
        expect(AssetExtension.tryParse('jpeg'), AssetExtension.jpeg);
      });

      test('parses jpg as jpeg (aliased)', () {
        expect(AssetExtension.tryParse('jpg'), AssetExtension.jpeg);
      });

      test('parses gif extension', () {
        expect(AssetExtension.tryParse('gif'), AssetExtension.gif);
      });

      test('parses webp extension', () {
        expect(AssetExtension.tryParse('webp'), AssetExtension.webp);
      });

      test('parses svg extension', () {
        expect(AssetExtension.tryParse('svg'), AssetExtension.svg);
      });

      test('handles uppercase input', () {
        expect(AssetExtension.tryParse('PNG'), AssetExtension.png);
        expect(AssetExtension.tryParse('JPEG'), AssetExtension.jpeg);
        expect(AssetExtension.tryParse('JPG'), AssetExtension.jpeg);
        expect(AssetExtension.tryParse('GIF'), AssetExtension.gif);
      });

      test('handles mixed case input', () {
        expect(AssetExtension.tryParse('Png'), AssetExtension.png);
        expect(AssetExtension.tryParse('JpEg'), AssetExtension.jpeg);
      });

      test('returns null for unknown extensions', () {
        expect(AssetExtension.tryParse('bmp'), isNull);
        expect(AssetExtension.tryParse('tiff'), isNull);
        expect(AssetExtension.tryParse(''), isNull);
        expect(AssetExtension.tryParse('unknown'), isNull);
      });
    });

    group('toJson', () {
      test('returns enum name as string', () {
        expect(AssetExtension.png.toJson(), 'png');
        expect(AssetExtension.jpeg.toJson(), 'jpeg');
        expect(AssetExtension.gif.toJson(), 'gif');
        expect(AssetExtension.webp.toJson(), 'webp');
        expect(AssetExtension.svg.toJson(), 'svg');
      });
    });

    group('fromJson', () {
      test('parses valid enum names', () {
        expect(AssetExtension.fromJson('png'), AssetExtension.png);
        expect(AssetExtension.fromJson('jpeg'), AssetExtension.jpeg);
        expect(AssetExtension.fromJson('gif'), AssetExtension.gif);
        expect(AssetExtension.fromJson('webp'), AssetExtension.webp);
        expect(AssetExtension.fromJson('svg'), AssetExtension.svg);
      });

      test('throws ArgumentError for invalid value', () {
        expect(
          () => AssetExtension.fromJson('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws for jpg (not aliased in fromJson)', () {
        // Note: fromJson expects exact enum names, not the aliased 'jpg'
        expect(
          () => AssetExtension.fromJson('jpg'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('schema', () {
      test('validates all enum values', () {
        expect(AssetExtension.schema.safeParse('png').isOk, isTrue);
        expect(AssetExtension.schema.safeParse('jpeg').isOk, isTrue);
        expect(AssetExtension.schema.safeParse('gif').isOk, isTrue);
        expect(AssetExtension.schema.safeParse('webp').isOk, isTrue);
        expect(AssetExtension.schema.safeParse('svg').isOk, isTrue);
      });

      test('rejects invalid values', () {
        expect(AssetExtension.schema.safeParse('invalid').isOk, isFalse);
        expect(AssetExtension.schema.safeParse('bmp').isOk, isFalse);
      });
    });
  });

  group('GeneratedAsset', () {
    group('constructor and properties', () {
      test('creates asset with required properties', () {
        final asset = GeneratedAsset(
          name: 'test_asset',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );

        expect(asset.name, 'test_asset');
        expect(asset.extension, AssetExtension.png);
        expect(asset.type, 'thumbnail');
      });

      test('fileName getter combines type, name, and extension', () {
        final asset = GeneratedAsset(
          name: 'slide_1',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );

        expect(asset.fileName, 'thumbnail_slide_1.png');
      });

      test('fileName works with different extensions', () {
        final jpegAsset = GeneratedAsset(
          name: 'image_hash',
          extension: AssetExtension.jpeg,
          type: 'image',
        );

        expect(jpegAsset.fileName, 'image_image_hash.jpeg');
      });
    });

    group('buildKey', () {
      test('generates hash for value', () {
        final key1 = GeneratedAsset.buildKey('some content');
        final key2 = GeneratedAsset.buildKey('some content');
        final key3 = GeneratedAsset.buildKey('different content');

        expect(key1, equals(key2));
        expect(key1, isNot(equals(key3)));
      });

      test('generates consistent hash', () {
        // Hash should be deterministic
        final key = GeneratedAsset.buildKey('test value');
        expect(key, isNotEmpty);
        expect(GeneratedAsset.buildKey('test value'), key);
      });
    });

    group('factory methods', () {
      test('thumbnail creates png asset with thumbnail type', () {
        final asset = GeneratedAsset.thumbnail('slide_key_123');

        expect(asset.name, 'slide_key_123');
        expect(asset.extension, AssetExtension.png);
        expect(asset.type, 'thumbnail');
      });

      test('mermaid creates png asset with mermaid type', () {
        const syntax = 'graph TD; A-->B;';
        final asset = GeneratedAsset.mermaid(syntax);

        expect(asset.name, GeneratedAsset.buildKey(syntax));
        expect(asset.extension, AssetExtension.png);
        expect(asset.type, 'mermaid');
      });

      test('image creates asset with specified extension', () {
        const url = 'https://example.com/image.webp';
        final asset = GeneratedAsset.image(url, AssetExtension.webp);

        expect(asset.name, GeneratedAsset.buildKey(url));
        expect(asset.extension, AssetExtension.webp);
        expect(asset.type, 'image');
      });

      test('image works with different extensions', () {
        const url = 'https://example.com/photo.jpg';

        final pngAsset = GeneratedAsset.image(url, AssetExtension.png);
        expect(pngAsset.extension, AssetExtension.png);

        final jpegAsset = GeneratedAsset.image(url, AssetExtension.jpeg);
        expect(jpegAsset.extension, AssetExtension.jpeg);
      });
    });

    group('copyWith', () {
      test('creates copy with same values when no arguments', () {
        final original = GeneratedAsset(
          name: 'original',
          extension: AssetExtension.png,
          type: 'test',
        );

        final copy = original.copyWith();

        expect(copy.name, original.name);
        expect(copy.extension, original.extension);
        expect(copy.type, original.type);
        expect(copy, isNot(same(original)));
      });

      test('replaces name when specified', () {
        final original = GeneratedAsset(
          name: 'original',
          extension: AssetExtension.png,
          type: 'test',
        );

        final copy = original.copyWith(name: 'new_name');

        expect(copy.name, 'new_name');
        expect(copy.extension, original.extension);
        expect(copy.type, original.type);
      });

      test('replaces extension when specified', () {
        final original = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'test',
        );

        final copy = original.copyWith(extension: AssetExtension.jpeg);

        expect(copy.name, original.name);
        expect(copy.extension, AssetExtension.jpeg);
        expect(copy.type, original.type);
      });

      test('replaces type when specified', () {
        final original = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'original_type',
        );

        final copy = original.copyWith(type: 'new_type');

        expect(copy.name, original.name);
        expect(copy.extension, original.extension);
        expect(copy.type, 'new_type');
      });

      test('replaces multiple values at once', () {
        final original = GeneratedAsset(
          name: 'old',
          extension: AssetExtension.png,
          type: 'old_type',
        );

        final copy = original.copyWith(
          name: 'new',
          extension: AssetExtension.gif,
          type: 'new_type',
        );

        expect(copy.name, 'new');
        expect(copy.extension, AssetExtension.gif);
        expect(copy.type, 'new_type');
      });
    });

    group('serialization', () {
      test('toMap returns correct structure', () {
        final asset = GeneratedAsset(
          name: 'test_asset',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );

        final map = asset.toMap();

        expect(map, {
          'name': 'test_asset',
          'extension': 'png',
          'type': 'thumbnail',
        });
      });

      test('fromMap parses correctly', () {
        final map = {
          'name': 'parsed_asset',
          'extension': 'jpeg',
          'type': 'image',
        };

        final asset = GeneratedAsset.fromMap(map);

        expect(asset.name, 'parsed_asset');
        expect(asset.extension, AssetExtension.jpeg);
        expect(asset.type, 'image');
      });

      test('round-trip serialization preserves data', () {
        final original = GeneratedAsset(
          name: 'round_trip',
          extension: AssetExtension.webp,
          type: 'mermaid',
        );

        final restored = GeneratedAsset.fromMap(original.toMap());

        expect(restored.name, original.name);
        expect(restored.extension, original.extension);
        expect(restored.type, original.type);
        expect(restored, original);
      });
    });

    group('equality and hashCode', () {
      test('equal assets are equal', () {
        final asset1 = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );
        final asset2 = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );

        expect(asset1, equals(asset2));
        expect(asset1.hashCode, equals(asset2.hashCode));
      });

      test('different names are not equal', () {
        final asset1 = GeneratedAsset(
          name: 'name1',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );
        final asset2 = GeneratedAsset(
          name: 'name2',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );

        expect(asset1, isNot(equals(asset2)));
      });

      test('different extensions are not equal', () {
        final asset1 = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );
        final asset2 = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.jpeg,
          type: 'thumbnail',
        );

        expect(asset1, isNot(equals(asset2)));
      });

      test('different types are not equal', () {
        final asset1 = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );
        final asset2 = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'mermaid',
        );

        expect(asset1, isNot(equals(asset2)));
      });

      test('identical returns true for same instance', () {
        final asset = GeneratedAsset(
          name: 'test',
          extension: AssetExtension.png,
          type: 'thumbnail',
        );

        expect(identical(asset, asset), isTrue);
        expect(asset == asset, isTrue);
      });
    });

    group('schema', () {
      test('validates correct structure', () {
        final valid = {
          'name': 'test',
          'extension': 'png',
          'type': 'thumbnail',
        };

        expect(GeneratedAsset.schema.safeParse(valid).isOk, isTrue);
      });

      test('rejects missing fields', () {
        final missingName = {'extension': 'png', 'type': 'thumbnail'};
        final missingExt = {'name': 'test', 'type': 'thumbnail'};
        final missingType = {'name': 'test', 'extension': 'png'};

        expect(GeneratedAsset.schema.safeParse(missingName).isOk, isFalse);
        expect(GeneratedAsset.schema.safeParse(missingExt).isOk, isFalse);
        expect(GeneratedAsset.schema.safeParse(missingType).isOk, isFalse);
      });

      test('rejects invalid extension', () {
        final invalid = {
          'name': 'test',
          'extension': 'invalid',
          'type': 'thumbnail',
        };

        expect(GeneratedAsset.schema.safeParse(invalid).isOk, isFalse);
      });
    });
  });

  group('GeneratedAssetsReference', () {
    group('constructor and properties', () {
      test('creates reference with required properties', () {
        final lastModified = DateTime(2024, 1, 15, 10, 30, 0);
        final files = ['file1.png', 'file2.png'];

        final ref = GeneratedAssetsReference(
          lastModified: lastModified,
          files: files,
        );

        expect(ref.lastModified, lastModified);
        expect(ref.files, files);
      });
    });

    group('copyWith', () {
      test('creates copy with same values when no arguments', () {
        final original = GeneratedAssetsReference(
          lastModified: DateTime(2024, 1, 1),
          files: ['a.png', 'b.png'],
        );

        final copy = original.copyWith();

        expect(copy.lastModified, original.lastModified);
        expect(copy.files, original.files);
      });

      test('replaces lastModified when specified', () {
        final original = GeneratedAssetsReference(
          lastModified: DateTime(2024, 1, 1),
          files: ['a.png'],
        );
        final newDate = DateTime(2024, 6, 15);

        final copy = original.copyWith(lastModified: newDate);

        expect(copy.lastModified, newDate);
        expect(copy.files, original.files);
      });

      test('replaces files when specified', () {
        final original = GeneratedAssetsReference(
          lastModified: DateTime(2024, 1, 1),
          files: ['old.png'],
        );
        final newFiles = ['new1.png', 'new2.png'];

        final copy = original.copyWith(files: newFiles);

        expect(copy.lastModified, original.lastModified);
        expect(copy.files, newFiles);
      });
    });

    group('serialization', () {
      test('toMap returns correct structure', () {
        final ref = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 3, 15, 12, 30, 45),
          files: ['thumbnail_1.png', 'mermaid_abc.png'],
        );

        final map = ref.toMap();

        expect(map['last_modified'], '2024-03-15T12:30:45.000Z');
        expect(map['files'], ['thumbnail_1.png', 'mermaid_abc.png']);
      });

      test('fromMap parses correctly', () {
        final map = {
          'last_modified': '2024-06-20T08:15:30.000Z',
          'files': ['file1.png', 'file2.jpeg'],
        };

        final ref = GeneratedAssetsReference.fromMap(map);

        expect(ref.lastModified, DateTime.utc(2024, 6, 20, 8, 15, 30));
        expect(ref.files, ['file1.png', 'file2.jpeg']);
      });

      test('round-trip serialization preserves data', () {
        final original = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 12, 25, 23, 59, 59),
          files: ['a.png', 'b.png', 'c.png'],
        );

        final restored = GeneratedAssetsReference.fromMap(original.toMap());

        expect(restored.lastModified, original.lastModified);
        expect(restored.files, original.files);
        expect(restored, original);
      });

      test('handles empty files list', () {
        final ref = GeneratedAssetsReference(
          lastModified: DateTime(2024, 1, 1),
          files: [],
        );

        final restored = GeneratedAssetsReference.fromMap(ref.toMap());

        expect(restored.files, isEmpty);
      });
    });

    group('equality and hashCode', () {
      test('equal references are equal', () {
        final ref1 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 1),
          files: ['a.png', 'b.png'],
        );
        final ref2 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 1),
          files: ['a.png', 'b.png'],
        );

        expect(ref1, equals(ref2));
        expect(ref1.hashCode, equals(ref2.hashCode));
      });

      test('different dates are not equal', () {
        final ref1 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 1),
          files: ['a.png'],
        );
        final ref2 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 2),
          files: ['a.png'],
        );

        expect(ref1, isNot(equals(ref2)));
      });

      test('different files are not equal', () {
        final ref1 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 1),
          files: ['a.png'],
        );
        final ref2 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 1),
          files: ['b.png'],
        );

        expect(ref1, isNot(equals(ref2)));
      });

      test('different file order makes references not equal', () {
        final ref1 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 1),
          files: ['a.png', 'b.png'],
        );
        final ref2 = GeneratedAssetsReference(
          lastModified: DateTime.utc(2024, 1, 1),
          files: ['b.png', 'a.png'],
        );

        // ListEquality considers order
        expect(ref1, isNot(equals(ref2)));
      });

      test('identical returns true for same instance', () {
        final ref = GeneratedAssetsReference(
          lastModified: DateTime(2024, 1, 1),
          files: ['a.png'],
        );

        expect(identical(ref, ref), isTrue);
        expect(ref == ref, isTrue);
      });
    });
  });
}
