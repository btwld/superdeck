import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../../markdown/markdown_helpers.dart';
import 'hero_element.dart';

/// Flies resolved endpoint paragraphs without reflowing them inside the Hero.
///
/// The original constraints determine line breaks. The animated Hero rectangle
/// only positions and uniformly scales those fixed layouts. Copying RenderParagraph
/// data also preserves the endpoint's inherited styles, direction and text scaler.
Widget buildTextHeroFlight(
  BuildContext context,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  return _buildFlight(
    animation,
    direction,
    _ParagraphLayout.capture(fromContext),
    _ParagraphLayout.capture(toContext),
  );
}

/// Uses the same fixed-layout reveal for the complete highlighted code block.
Widget buildCodeHeroFlight(
  BuildContext context,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) => _buildFlight(
  animation,
  direction,
  _ParagraphLayout.capture(
    fromContext,
    container: HeroElement.of<CodeElement>(fromContext).spec.container,
    framed: true,
  ),
  _ParagraphLayout.capture(
    toContext,
    container: HeroElement.of<CodeElement>(toContext).spec.container,
    framed: true,
  ),
);

Widget _buildFlight(
  Animation<double> animation,
  HeroFlightDirection direction,
  _ParagraphLayout from,
  _ParagraphLayout to,
) {
  final identical = from.matches(to);
  // An unchanged line can share one continuously moving glyph rectangle.
  // Transform fixed endpoint layouts instead of reshaping text at fractional
  // font sizes, which introduces hinting/baseline jitter despite smooth frames.
  final morphSingleLine =
      !identical &&
      !from.framed &&
      !to.framed &&
      from.singleLine &&
      to.singleLine &&
      from.glyphBounds != null &&
      to.glyphBounds != null &&
      from.text.textDirection == to.text.textDirection &&
      from.text.textScaler == to.text.textScaler &&
      from.text.textAlign == to.text.textAlign &&
      from.text.strutStyle == to.text.strutStyle &&
      from.text.locale == to.text.locale &&
      from.text.textHeightBehavior == to.text.textHeightBehavior &&
      from.text.textWidthBasis == to.text.textWidthBasis &&
      _matchingSpanStructure(from.text.text, to.text.text);

  return ExcludeSemantics(
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = direction == .push ? animation.value : 1 - animation.value;
          if (morphSingleLine) return from.interpolateSingleLine(to, t);
          // Limit overlapping copy to the middle of the flight; a full-duration
          // dissolve makes differently shaped letters look like a drop shadow.
          final blend = const Interval(
            0.4,
            0.6,
            curve: Curves.easeInOut,
          ).transform(t);

          return Stack(
            fit: .expand,
            children: [
              if (from.framed || to.framed)
                Box(
                  styleSpec:
                      (from.container ?? const StyleSpec(spec: BoxSpec())).lerp(
                        to.container ?? const StyleSpec(spec: BoxSpec()),
                        t,
                      ),
                  child: const SizedBox.expand(),
                ),
              if (identical || blend < 1)
                Opacity(
                  opacity: identical ? 1 : 1 - blend,
                  child: from.build(
                    reveal: _reveal(from, to, t < 0.5 ? t : 0.5),
                  ),
                ),
              if (!identical && blend > 0)
                Opacity(
                  opacity: blend,
                  child: to.build(reveal: _reveal(from, to, t > 0.5 ? t : 0.5)),
                ),
            ],
          );
        },
      ),
    ),
  );
}

LerpStringResult? _reveal(
  _ParagraphLayout from,
  _ParagraphLayout to,
  double t,
) {
  const typing = bool.fromEnvironment(
    'SUPERDECK_ANIMATE_HERO_TEXT',
    defaultValue: true,
  );
  final start = from.text.text.toPlainText();
  final end = to.text.text.toPlainText();
  if (!typing || start == end) return null;

  return lerpStringWithFade(start, end, t);
}

/// Changes only paint, retaining all characters and their original styles.
InlineSpan _mask(InlineSpan root, LerpStringResult reveal) {
  if (reveal.text == root.toPlainText()) return root;
  var offset = 0;
  final visibleEnd = reveal.text.length;
  final fadeEnd = visibleEnd + (reveal.fadingChar?.length ?? 0);
  InlineSpan visit(InlineSpan node, TextStyle inherited) {
    if (node is! TextSpan) return node;
    final style = inherited.merge(node.style);
    final pieces = <InlineSpan>[];
    final value = node.text ?? '';
    var local = 0;
    while (local < value.length) {
      final position = offset + local;
      final boundary = position < visibleEnd
          ? visibleEnd
          : position < fadeEnd
          ? fadeEnd
          : offset + value.length;
      final end = (boundary - offset).clamp(local + 1, value.length);
      final opacity = position < visibleEnd
          ? 1.0
          : position < fadeEnd
          ? reveal.fadeOpacity
          : 0.0;
      final color = style.color ?? const Color(0xFF000000);
      pieces.add(
        TextSpan(
          text: value.substring(local, end),
          style: style.copyWith(
            color: color.withValues(alpha: color.a * opacity),
          ),
        ),
      );
      local = end;
    }
    offset += value.length;
    for (final child in node.children ?? const <InlineSpan>[]) {
      pieces.add(visit(child, style));
    }

    return TextSpan(children: pieces, style: style);
  }

  return visit(root, const TextStyle());
}

bool _matchingSpanStructure(InlineSpan from, InlineSpan to) {
  if (from is! TextSpan || to is! TextSpan || from.text != to.text) {
    return false;
  }
  // Different families can have substantially different glyph proportions;
  // keep those on the general endpoint path instead of stretching one line
  // to match the other family's geometry.
  if (from.style?.fontFamily != to.style?.fontFamily ||
      !listEquals(
        from.style?.fontFamilyFallback,
        to.style?.fontFamilyFallback,
      )) {
    return false;
  }
  final fromChildren = from.children ?? const <InlineSpan>[];
  final toChildren = to.children ?? const <InlineSpan>[];
  if (fromChildren.length != toChildren.length) return false;
  for (var i = 0; i < fromChildren.length; i++) {
    if (!_matchingSpanStructure(fromChildren[i], toChildren[i])) return false;
  }

  return true;
}

class _ParagraphLayout {
  final RichText text;
  final Size size;
  final BoxConstraints constraints;
  final Alignment alignment;
  final Size frameSize;
  final Offset offset;
  final StyleSpec<BoxSpec>? container;
  final bool framed;
  final bool singleLine;
  final Rect? glyphBounds;

  const _ParagraphLayout(
    this.text,
    this.size,
    this.constraints,
    this.alignment,
    this.frameSize,
    this.offset,
    this.container,
    this.framed,
    this.singleLine,
    this.glyphBounds,
  );

  factory _ParagraphLayout.capture(
    BuildContext context, {
    StyleSpec<BoxSpec>? container,
    bool framed = false,
  }) {
    RenderParagraph? paragraph;
    void findParagraph(RenderObject object) {
      if (paragraph != null) return;
      if (object is RenderParagraph) {
        paragraph = object;
      } else {
        object.visitChildren(findParagraph);
      }
    }

    findParagraph(context.findRenderObject()!);
    final render = paragraph!;
    final painter =
        TextPainter(
          text: render.text,
          textAlign: render.textAlign,
          textDirection: render.textDirection,
          textScaler: render.textScaler,
          locale: render.locale,
          strutStyle: render.strutStyle,
          textWidthBasis: render.textWidthBasis,
          textHeightBehavior: render.textHeightBehavior,
        )..layout(
          minWidth: render.constraints.minWidth,
          maxWidth: render.softWrap ? render.constraints.maxWidth : .infinity,
        );
    final singleLine =
        painter.computeLineMetrics().length == 1 && !render.didExceedMaxLines;
    painter.dispose();
    Rect? glyphBounds;
    if (singleLine) {
      for (final box in render.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: render.text.toPlainText().length,
        ),
      )) {
        final rect = box.toRect();
        if (!rect.isEmpty) {
          glyphBounds = glyphBounds?.expandToInclude(rect) ?? rect;
        }
      }
    }
    final alignment = switch (render.textAlign) {
      .center => Alignment.center,
      .right => Alignment.centerRight,
      .left => Alignment.centerLeft,
      .end =>
        render.textDirection == .ltr
            ? Alignment.centerRight
            : Alignment.centerLeft,
      .start || .justify =>
        render.textDirection == .ltr
            ? Alignment.centerLeft
            : Alignment.centerRight,
    };

    return _ParagraphLayout(
      RichText(
        text: render.text,
        textAlign: render.textAlign,
        textDirection: render.textDirection,
        softWrap: render.softWrap,
        overflow: render.overflow,
        textScaler: render.textScaler,
        maxLines: render.maxLines,
        locale: render.locale,
        strutStyle: render.strutStyle,
        textWidthBasis: render.textWidthBasis,
        textHeightBehavior: render.textHeightBehavior,
      ),
      render.size,
      render.constraints,
      alignment,
      !framed ? render.size : (context.findRenderObject()! as RenderBox).size,
      !framed
          ? .zero
          : render.localToGlobal(.zero, ancestor: context.findRenderObject()!),
      container,
      framed,
      singleLine,
      glyphBounds,
    );
  }

  Widget _mappedLine(Rect target, {required double opacity}) {
    final bounds = glyphBounds!;
    final transform = Matrix4.identity()
      ..translateByDouble(target.left, target.top, 0, 1)
      ..scaleByDouble(
        target.width / bounds.width,
        target.height / bounds.height,
        1,
        1,
      )
      ..translateByDouble(-bounds.left, -bounds.top, 0, 1);

    return Positioned(
      left: 0,
      top: 0,
      width: size.width,
      height: size.height,
      child: Transform(
        transform: transform,
        child: _TextBlend(
          opacity: opacity,
          blendMode: .plus,
          child: _fixedParagraph(text),
        ),
      ),
    );
  }

  Widget _fixedParagraph(RichText richText) => SizedBox.fromSize(
    size: size,
    child: OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
      minHeight: constraints.minHeight,
      maxHeight: constraints.maxHeight,
      child: richText,
    ),
  );

  bool matches(_ParagraphLayout other) =>
      framed == other.framed &&
      frameSize == other.frameSize &&
      offset == other.offset &&
      container == other.container &&
      size == other.size &&
      constraints == other.constraints &&
      alignment == other.alignment &&
      text.text.compareTo(other.text.text) == .identical &&
      text.textAlign == other.text.textAlign &&
      text.textDirection == other.text.textDirection &&
      text.softWrap == other.text.softWrap &&
      text.overflow == other.text.overflow &&
      text.textScaler == other.text.textScaler &&
      text.maxLines == other.text.maxLines &&
      text.locale == other.text.locale &&
      text.strutStyle == other.text.strutStyle &&
      text.textWidthBasis == other.text.textWidthBasis &&
      text.textHeightBehavior == other.text.textHeightBehavior;

  Widget interpolateSingleLine(_ParagraphLayout to, double t) {
    final target = Rect.lerp(glyphBounds, to.glyphBounds, t)!;

    return FittedBox(
      fit: .contain,
      alignment: Alignment.lerp(alignment, to.alignment, t)!,
      child: SizedBox.fromSize(
        size: Size.lerp(size, to.size, t),
        child: _TextBlend(
          child: Stack(
            clipBehavior: .none,
            children: [
              _mappedLine(target, opacity: 1 - t),
              to._mappedLine(target, opacity: t),
            ],
          ),
        ),
      ),
    );
  }

  Widget build({LerpStringResult? reveal}) {
    final richText = reveal == null
        ? text
        : RichText(
            text: _mask(text.text, reveal),
            textAlign: text.textAlign,
            textDirection: text.textDirection,
            softWrap: text.softWrap,
            overflow: text.overflow,
            textScaler: text.textScaler,
            maxLines: text.maxLines,
            locale: text.locale,
            strutStyle: text.strutStyle,
            textWidthBasis: text.textWidthBasis,
            textHeightBehavior: text.textHeightBehavior,
          );
    final paragraph = _fixedParagraph(richText);

    return FittedBox(
      fit: .contain,
      alignment: alignment,
      child: !framed
          ? paragraph
          : SizedBox.fromSize(
              size: frameSize,
              child: Stack(
                children: [
                  Positioned(left: offset.dx, top: offset.dy, child: paragraph),
                ],
              ),
            ),
    );
  }
}

/// Blends the two fixed, non-composited paragraph layouts in an isolated layer.
/// Additive premultiplied alpha avoids the 25% brightness dip of stacking two
/// half-opaque copies at the midpoint. Only paint changes; glyph layout stays put.
class _TextBlend extends SingleChildRenderObjectWidget {
  const _TextBlend({
    required super.child,
    this.opacity = 1,
    this.blendMode = BlendMode.srcOver,
  });

  final double opacity;

  final BlendMode blendMode;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTextBlend(opacity, blendMode);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTextBlend renderObject,
  ) => renderObject.update(opacity, blendMode);
}

class _RenderTextBlend extends RenderProxyBox {
  double _opacity;
  BlendMode _blendMode;

  _RenderTextBlend(this._opacity, this._blendMode);

  void update(double opacity, BlendMode blendMode) {
    if (_opacity == opacity && _blendMode == blendMode) return;
    _opacity = opacity;
    _blendMode = blendMode;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_opacity == 0 || child == null) return;
    // This private subtree contains only fixed RichText (no WidgetSpans or
    // repaint boundaries), so all children paint into this same canvas.
    assert(!child!.needsCompositing);
    final canvas = context.canvas;
    canvas.saveLayer(
      offset & size,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, _opacity)
        ..blendMode = _blendMode,
    );
    super.paint(context, offset);
    canvas.restore();
  }
}
