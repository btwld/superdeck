import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart' show BlockVariant;
import 'package:superdeck/src/styling/block_variant.dart'
    show BlockVariantScope;

void main() {
  group('BlockVariant', () {
    testWidgets('matches only the exact, case-sensitive block name', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BlockVariantScope(
            name: 'webview',
            child: Builder(
              builder: (context) {
                expect(const BlockVariant('webview').when(context), isTrue);
                expect(
                  const BlockVariant('webview').shouldApply(context),
                  isTrue,
                );
                expect(const BlockVariant('WebView').when(context), isFalse);
                expect(
                  const BlockVariant('WebView').shouldApply(context),
                  isFalse,
                );
                expect(const BlockVariant('image').when(context), isFalse);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('uses the nearest scope for nested widget blocks', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BlockVariantScope(
            name: 'webview',
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    expect(const BlockVariant('webview').when(context), isTrue);
                    return const SizedBox.shrink();
                  },
                ),
                BlockVariantScope(
                  name: 'chart',
                  child: Builder(
                    builder: (context) {
                      expect(const BlockVariant('chart').when(context), isTrue);
                      expect(
                        const BlockVariant('webview').when(context),
                        isFalse,
                      );
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Builder(
                  builder: (context) {
                    expect(const BlockVariant('webview').when(context), isTrue);
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('does not leak outside its widget subtree', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              BlockVariantScope(
                name: 'image',
                child: Builder(
                  builder: (context) {
                    expect(const BlockVariant('image').when(context), isTrue);
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Builder(
                builder: (context) {
                  expect(const BlockVariant('image').when(context), isFalse);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );
    });
  });
}
