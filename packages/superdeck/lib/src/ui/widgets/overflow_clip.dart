import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A debug-only description of content that paints outside its assigned frame.
@immutable
class OverflowDiagnosticIssue {
  OverflowDiagnosticIssue({
    required this.slideKey,
    required this.runtimeKey,
    required this.availableSize,
    required this.measuredSize,
    required Set<Axis> axes,
  }) : axes = Set.unmodifiable(axes);

  final String slideKey;
  final String runtimeKey;
  final Size availableSize;
  final Size measuredSize;
  final Set<Axis> axes;

  String get stableSignature => [
    for (final axis in Axis.values)
      if (axes.contains(axis)) axis.name,
  ].join(',');

  String get message {
    final axis = stableSignature;
    return 'SuperDeck overflow: slide=$slideKey block=$runtimeKey '
        'available=${_formatSize(availableSize)} '
        'measured=${_formatSize(measuredSize)} axis=$axis';
  }
}

String _formatSize(Size size) {
  return '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}';
}

/// Internal debug reporter that emits each stable block/axis issue once.
///
/// This is intentionally not exported from the public package API. The logger
/// and active-issue view exist only to make diagnostics deterministic in tests.
class OverflowDiagnostics {
  OverflowDiagnostics._();

  static final _activeIssues = <String, OverflowDiagnosticIssue>{};

  @visibleForTesting
  static ValueChanged<String>? logger;

  @visibleForTesting
  static Map<String, OverflowDiagnosticIssue> get activeIssuesForTesting =>
      Map.unmodifiable(_activeIssues);

  static void report(OverflowDiagnosticIssue issue) {
    final previous = _activeIssues[issue.runtimeKey];
    _activeIssues[issue.runtimeKey] = issue;
    if (previous?.stableSignature == issue.stableSignature) return;

    final activeLogger = logger;
    if (activeLogger != null) {
      activeLogger(issue.message);
    } else {
      debugPrint(issue.message);
    }
  }

  static void clear(String runtimeKey) {
    _activeIssues.remove(runtimeKey);
  }

  @visibleForTesting
  static void resetForTesting() {
    _activeIssues.clear();
    logger = null;
  }
}

/// Observes an already-laid-out Markdown subtree for debug overflow.
///
/// The render proxy forwards the exact incoming constraints to [child]. It
/// never performs an intrinsic pass, a second layout, or a duplicate build.
class OverflowDiagnosticProbe extends SingleChildRenderObjectWidget {
  const OverflowDiagnosticProbe({
    super.key,
    required this.slideKey,
    required this.runtimeKey,
    required this.availableSize,
    this.indicatorColor = const Color(0xFFFF3B30),
    required super.child,
  });

  final String slideKey;
  final String runtimeKey;
  final Size availableSize;
  final Color indicatorColor;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverflowDiagnosticProbe(
      slideKey: slideKey,
      runtimeKey: runtimeKey,
      availableSize: availableSize,
      indicatorColor: indicatorColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderOverflowDiagnosticProbe)
      ..slideKey = slideKey
      ..runtimeKey = runtimeKey
      ..availableSize = availableSize
      ..indicatorColor = indicatorColor;
  }
}

class _RenderOverflowDiagnosticProbe extends RenderProxyBox {
  _RenderOverflowDiagnosticProbe({
    required String slideKey,
    required String runtimeKey,
    required Size availableSize,
    required Color indicatorColor,
  }) : _slideKey = slideKey,
       _runtimeKey = runtimeKey,
       _availableSize = availableSize,
       _indicatorColor = indicatorColor;

  static const _overflowTolerance = 0.5;
  static const _indicatorStrokeWidth = 2.0;

  String _slideKey;
  String _runtimeKey;
  Size _availableSize;
  Color _indicatorColor;
  OverflowDiagnosticIssue? _issue;
  int _notificationSerial = 0;

  set slideKey(String value) {
    if (_slideKey == value) return;
    _slideKey = value;
    markNeedsPaint();
  }

  set runtimeKey(String value) {
    if (_runtimeKey == value) return;
    OverflowDiagnostics.clear(_runtimeKey);
    _runtimeKey = value;
    markNeedsPaint();
  }

  set availableSize(Size value) {
    if (_availableSize == value) return;
    _availableSize = value;
    markNeedsPaint();
  }

  set indicatorColor(Color value) {
    if (_indicatorColor == value) return;
    _indicatorColor = value;
    markNeedsPaint();
  }

  OverflowDiagnosticIssue? _measureIssue() {
    final renderChild = child;
    if (renderChild == null || !renderChild.hasSize) return null;
    final availableSize = _effectiveAvailableSize;

    var paintedBounds = Offset.zero & renderChild.size;

    void includeBox(RenderBox box) {
      if (!box.hasSize) return;
      final transform = box.getTransformTo(this);
      final bounds = MatrixUtils.transformRect(transform, box.paintBounds);
      if (_isFinite(bounds)) {
        paintedBounds = paintedBounds.expandToInclude(bounds);
      }

      if (box is RenderParagraph) {
        final textLength = box.text.toPlainText().length;
        if (textLength > 0) {
          try {
            final textBoxes = box.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: textLength),
            );
            for (final textBox in textBoxes) {
              final textBounds = MatrixUtils.transformRect(
                transform,
                Rect.fromLTRB(
                  textBox.left,
                  textBox.top,
                  textBox.right,
                  textBox.bottom,
                ),
              );
              if (_isFinite(textBounds)) {
                paintedBounds = paintedBounds.expandToInclude(textBounds);
              }
            }
          } on FlutterError {
            // A transient paragraph without text layout is not diagnosable yet.
          }
        }
      }
    }

    void visit(RenderObject object) {
      object.visitChildren((descendant) {
        if (descendant case final RenderBox box) includeBox(box);
        visit(descendant);
      });
    }

    includeBox(renderChild);
    visit(renderChild);

    final axes = <Axis>{};
    if (paintedBounds.left < -_overflowTolerance ||
        paintedBounds.right > availableSize.width + _overflowTolerance) {
      axes.add(Axis.horizontal);
    }
    if (paintedBounds.top < -_overflowTolerance ||
        paintedBounds.bottom > availableSize.height + _overflowTolerance) {
      axes.add(Axis.vertical);
    }
    if (axes.isEmpty) return null;

    final measuredWidth =
        math.max(renderChild.size.width, paintedBounds.right) -
        math.min(0.0, paintedBounds.left);
    final measuredHeight =
        math.max(renderChild.size.height, paintedBounds.bottom) -
        math.min(0.0, paintedBounds.top);

    return OverflowDiagnosticIssue(
      slideKey: _slideKey,
      runtimeKey: _runtimeKey,
      availableSize: availableSize,
      measuredSize: Size(measuredWidth, measuredHeight),
      axes: axes,
    );
  }

  bool _isFinite(Rect rect) {
    return rect.left.isFinite &&
        rect.top.isFinite &&
        rect.right.isFinite &&
        rect.bottom.isFinite;
  }

  Size get _effectiveAvailableSize {
    return Size(
      constraints.hasBoundedWidth
          ? math.min(_availableSize.width, constraints.maxWidth)
          : _availableSize.width,
      constraints.hasBoundedHeight
          ? math.min(_availableSize.height, constraints.maxHeight)
          : _availableSize.height,
    );
  }

  void _scheduleNotification(OverflowDiagnosticIssue? issue) {
    final serial = ++_notificationSerial;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!attached || serial != _notificationSerial) return;
      if (issue == null) {
        OverflowDiagnostics.clear(_runtimeKey);
      } else {
        OverflowDiagnostics.report(issue);
      }
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _issue = _measureIssue();
    _scheduleNotification(_issue);
    super.paint(context, offset);
    if (_issue == null) return;

    final availableSize = _effectiveAvailableSize;
    final visibleWidth = math.min(size.width, availableSize.width);
    final visibleHeight = math.min(size.height, availableSize.height);
    if (visibleWidth <= 0 || visibleHeight <= 0) return;

    // Outline the visible frame instead of filling a corner so the indicator
    // never obscures content aligned to any frame edge.
    final strokeWidth = math.min(
      _indicatorStrokeWidth,
      math.min(visibleWidth, visibleHeight) / 2,
    );
    context.canvas.drawRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy,
        visibleWidth,
        visibleHeight,
      ).deflate(strokeWidth / 2),
      Paint()
        ..color = _indicatorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  void detach() {
    _notificationSerial++;
    OverflowDiagnostics.clear(_runtimeKey);
    super.detach();
  }
}

/// Clips overflow in a way that avoids layout assertions during size changes.
///
/// We intentionally use `Wrap` with `clipBehavior` for non-scrollable content
/// instead of `ClipRect` to avoid overflow assertions in transitional layouts
/// (for example, hero flights where size is interpolating).
class OverflowClip extends StatelessWidget {
  const OverflowClip({super.key, required this.child, this.scrollable = false});

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(child: child);
    }

    return Wrap(clipBehavior: Clip.hardEdge, children: [child]);
  }
}
