import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/styling/block_variant.dart'
    show BlockVariantScope;
import 'package:superdeck/superdeck.dart' show BlockStyler, BlockVariant;

/// Resolves [style] inside a widget tree, optionally under a
/// [BlockVariantScope] named [blockName].
Future<StyleSpec<BoxSpec>> resolveStyle(
  WidgetTester tester,
  BlockStyler style, {
  String? blockName,
}) async {
  late StyleSpec<BoxSpec> resolved;
  Widget child = Builder(
    builder: (context) {
      resolved = style.build(context);
      return const SizedBox.shrink();
    },
  );
  if (blockName != null) {
    child = BlockVariantScope(name: blockName, child: child);
  }
  await tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: child),
  );
  return resolved;
}

void main() {
  group('BlockStyler', () {
    testWidgets('resolves the supported surface to a BoxSpec', (tester) async {
      final style = BlockStyler(
        padding: EdgeInsetsGeometryMix.all(40),
        margin: EdgeInsetsGeometryMix.symmetric(horizontal: 8),
        decoration: BoxDecorationMix(
          color: const Color(0xFF112233),
          borderRadius: BorderRadiusMix.circular(10),
        ),
        foregroundDecoration: BoxDecorationMix(
          color: const Color(0x22000000),
        ),
        clipBehavior: Clip.antiAlias,
      );

      final resolved = await resolveStyle(tester, style);
      final spec = resolved.spec;

      expect(spec.padding, const EdgeInsets.all(40));
      expect(spec.margin, const EdgeInsets.symmetric(horizontal: 8));
      final decoration = spec.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF112233));
      expect(decoration.borderRadius, BorderRadius.circular(10));
      expect(
        (spec.foregroundDecoration as BoxDecoration).color,
        const Color(0x22000000),
      );
      expect(spec.clipBehavior, Clip.antiAlias);
    });

    testWidgets('never resolves widget modifiers or competing geometry', (
      tester,
    ) async {
      final style = BlockStyler(
        padding: EdgeInsetsGeometryMix.all(16),
      ).merge(BlockStyler(margin: EdgeInsetsGeometryMix.all(4)));

      final resolved = await resolveStyle(tester, style);

      expect(resolved.widgetModifiers, isNull);
      expect(resolved.spec.constraints, isNull);
      expect(resolved.spec.transform, isNull);
      expect(resolved.spec.alignment, isNull);
    });

    testWidgets('merge overrides matching insets and keeps decoration', (
      tester,
    ) async {
      final base = BlockStyler(
        padding: EdgeInsetsGeometryMix.all(40),
        decoration: BoxDecorationMix(color: const Color(0xFF445566)),
      );
      final override = BlockStyler(padding: EdgeInsetsGeometryMix.all(12));

      final resolved = await resolveStyle(tester, base.merge(override));

      expect(resolved.spec.padding, const EdgeInsets.all(12));
      expect(
        (resolved.spec.decoration as BoxDecoration).color,
        const Color(0xFF445566),
      );
    });

    testWidgets('applies a matching BlockVariant after the base style', (
      tester,
    ) async {
      final style = BlockStyler(padding: EdgeInsetsGeometryMix.all(40))
          .variant(
            const BlockVariant('image'),
            BlockStyler(padding: EdgeInsetsGeometryMix.all(0)),
          );

      final inScope = await resolveStyle(tester, style, blockName: 'image');
      expect(inScope.spec.padding, EdgeInsets.zero);

      final outOfScope = await resolveStyle(tester, style, blockName: 'chart');
      expect(outOfScope.spec.padding, const EdgeInsets.all(40));

      final noScope = await resolveStyle(tester, style);
      expect(noScope.spec.padding, const EdgeInsets.all(40));
    });

    testWidgets('supports Mix spacing convenience methods', (tester) async {
      final style = BlockStyler()
          .paddingAll(24)
          .marginOnly(top: 8, bottom: 4);

      final resolved = await resolveStyle(tester, style);

      expect(resolved.spec.padding, const EdgeInsets.all(24));
      expect(resolved.spec.margin, const EdgeInsets.only(top: 8, bottom: 4));
    });

    testWidgets('keeps animation metadata through merge', (tester) async {
      final style = BlockStyler(
        padding: EdgeInsetsGeometryMix.all(8),
      ).animate(AnimationConfig.linear(const Duration(milliseconds: 100)));

      final resolved = await resolveStyle(
        tester,
        style.merge(BlockStyler(margin: EdgeInsetsGeometryMix.all(2))),
      );

      expect(resolved.animation, isNotNull);
      expect(resolved.spec.padding, const EdgeInsets.all(8));
      expect(resolved.spec.margin, const EdgeInsets.all(2));
    });

    test('equal configurations are equal', () {
      BlockStyler build() => BlockStyler(
        padding: EdgeInsetsGeometryMix.all(40),
        decoration: BoxDecorationMix(color: const Color(0xFF112233)),
        clipBehavior: Clip.hardEdge,
      );

      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(BlockStyler(padding: EdgeInsetsGeometryMix.all(1))));
    });
  });
}
