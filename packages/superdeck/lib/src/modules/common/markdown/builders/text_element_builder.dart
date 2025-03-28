import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';
import 'package:superdeck/src/modules/deck/slide_configuration.dart';

import '../../../../components/molecules/block_provider.dart';
import '../../helpers/utils.dart';
import '../markdown_helpers.dart';
import 'element_data_provider.dart';

String _transformLineBreaks(String text) => text.replaceAll('<br>', '\n');

class TextElementBuilder extends MarkdownElementBuilder {
  final TextSpec? spec;
  TextElementBuilder(this.spec);
  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final (:tag, :content) = getTagAndContent(text.text);

    return Builder(builder: (context) {
      final block = BlockData.of(context);
      final slide = SlideConfiguration.of(context);

      final hasHero = tag != null && !slide.isExporting;

      final contentOffset = getTotalModifierSpacing(spec ?? const TextSpec());

      Widget current = TextSpecWidget(
        _transformLineBreaks(content),
        spec: spec,
      );

      if (hasHero) {
        current = _TextElementHero(
          tag: tag,
          child: current,
        );
      }
      return TextElementDataProvider(
        text: _transformLineBreaks(content),
        spec: spec ?? const TextSpec(),
        size: (block.size - contentOffset) as Size,
        child: current,
      );
    });
  }
}

class _TextElementHero extends StatelessWidget {
  const _TextElementHero({
    required this.tag,
    required this.child,
  });

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: child,
      flightShuttleBuilder: (
        BuildContext context,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        final toBlock =
            ElementDataProvider.of<TextElementDataProvider>(toHeroContext);
        final fromBlock = ElementDataProvider.maybeOf<TextElementDataProvider>(
              fromHeroContext,
            ) ??
            toBlock;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return TextSpecWidget(
              lerpString(fromBlock.text, toBlock.text, animation.value),
              spec: fromBlock.spec.lerp(toBlock.spec, animation.value),
            );
          },
        );
      },
    );
  }
}
