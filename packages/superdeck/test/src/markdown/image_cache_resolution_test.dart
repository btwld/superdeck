import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:superdeck/src/markdown/markdown_element_builders_registry.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/rendering/blocks/markdown_render_scope.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/ui/widgets/resolved_asset_image.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// A 1×1 transparent PNG — valid image bytes so MemoryImage decodes cleanly.
final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

const _key = 'slide-test-illustration.png';

void main() {
  group('In-slide image resolution via AssetCacheStore', () {
    testWidgets('a cached bare key resolves to a data: URI', (tester) async {
      final store = _FakeCacheStore({_key: _onePixelPng});

      await tester.pumpWidget(
        _MarkdownHarness(markdown: '![x]($_key)', assetCacheStore: store),
      );
      await tester.pumpAndSettle();

      // The builder took the cache path...
      expect(find.byType(ResolvedAssetImage), findsOneWidget);
      // ...and resolved the bare key to a data: URI (MemoryImage-backed).
      final cached = tester.widget<CachedImage>(find.byType(CachedImage));
      expect(cached.uri.scheme, 'data');
    });

    testWidgets('an uncached bare key falls back to the original ref', (
      tester,
    ) async {
      final store = _FakeCacheStore(const {}); // empty → cache miss

      await tester.pumpWidget(
        _MarkdownHarness(markdown: '![x]($_key)', assetCacheStore: store),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResolvedAssetImage), findsOneWidget);
      final cached = tester.widget<CachedImage>(find.byType(CachedImage));
      // Falls back to the bare (empty-scheme) reference — prior behavior.
      expect(cached.uri.scheme, isEmpty);
      expect(cached.uri.path, _key);
    });

    testWidgets('without a store, the original render path is unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(const _MarkdownHarness(markdown: '![x]($_key)'));
      await tester.pumpAndSettle();

      // No cache → no resolver widget; the bare ref is used directly.
      expect(find.byType(ResolvedAssetImage), findsNothing);
      final cached = tester.widget<CachedImage>(find.byType(CachedImage));
      expect(cached.uri.scheme, isEmpty);
    });
  });
}

class _FakeCacheStore implements AssetCacheStore {
  _FakeCacheStore(Map<String, Uint8List> seed)
    : _bytes = Map<String, Uint8List>.from(seed);

  final Map<String, Uint8List> _bytes;

  @override
  Future<Uri?> resolve(String assetKey) async {
    final bytes = _bytes[AssetCacheStore.validateAssetKey(assetKey)];
    if (bytes == null || bytes.isEmpty) return null;
    return Uri.dataFromBytes(bytes, mimeType: 'image/png');
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    final key = AssetCacheStore.validateAssetKey(assetKey);
    final data = Uint8List.fromList(bytes);
    _bytes[key] = data;
    return Uri.dataFromBytes(data, mimeType: 'image/png');
  }

  @override
  Future<void> delete(String assetKey) async {
    _bytes.remove(AssetCacheStore.validateAssetKey(assetKey));
  }
}

class _MarkdownHarness extends StatelessWidget {
  const _MarkdownHarness({required this.markdown, this.assetCacheStore});

  final String markdown;
  final AssetCacheStore? assetCacheStore;

  @override
  Widget build(BuildContext context) {
    final extensionSet = md.ExtensionSet.gitHubWeb;
    const slideSpec = SlideSpec();
    final registry = SpecMarkdownBuilders(slideSpec);
    final styleSheet = slideSpec.toStyle();
    final slideConfiguration = SlideConfiguration(
      slideIndex: 0,
      style: SlideStyle(),
      slide: Slide(key: 'slide'),
      thumbnailKey: 'thumb.png',
      assetCacheStore: assetCacheStore,
    );
    final blockData = BlockConfiguration(
      align: ContentBlock(markdown).resolvedAlign,
      spec: slideSpec,
      size: const Size(800, 600),
      runtimeKey: 'slide:s0:b0',
    );

    final tree = InheritedData<SlideConfiguration>(
      data: slideConfiguration,
      child: InheritedData<BlockConfiguration>(
        data: blockData,
        child: Scaffold(
          body: MarkdownRenderScope(
            registry: registry,
            styleSheet: styleSheet,
            extensionSet: extensionSet,
            child: MarkdownBody(
              data: markdown,
              extensionSet: extensionSet,
              blockSyntaxes: registry.blockSyntaxes,
              inlineSyntaxes: registry.inlineSyntaxes,
              builders: registry.builders,
              paddingBuilders: registry.paddingBuilders,
              checkboxBuilder: registry.checkboxBuilder,
              bulletBuilder: registry.bulletBuilder,
              styleSheet: styleSheet,
            ),
          ),
        ),
      ),
    );

    return MaterialApp(home: tree);
  }
}
