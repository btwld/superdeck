import 'package:flutter/material.dart';
import 'package:mermaid_core/mermaid_core.dart' as mermaid;
import 'package:mermaid_flutter/mermaid_flutter.dart';

import '../../capture/slide_capture_readiness.dart';
import '../mermaid/mermaid_source_check.dart';
import '../../ui/widgets/error_widgets.dart';

/// Renders a ```` ```mermaid ```` fence as a painted diagram.
///
/// The diagram is drawn by `mermaid_flutter` on the slide's own canvas: no
/// image asset, no build step, and no browser. It scales to the width its
/// Markdown block was given and keeps its own aspect ratio, the way an image
/// on a slide does.
///
/// A slide is a finished artefact, not a live editor, so a diagram that does
/// not render is reported instead of leaving the previous drawing on screen:
/// [MermaidDiagram.keepLastGoodSceneOnError] is off, and the failure is also
/// reported to [SlideCaptureReadiness] so an export that needs every visual
/// stops rather than writing a page with a missing diagram.
final class MermaidCodeBlock extends StatefulWidget {
  final String code;

  const MermaidCodeBlock({super.key, required this.code});

  @override
  State<MermaidCodeBlock> createState() => _MermaidCodeBlockState();
}

class _MermaidCodeBlockState extends State<MermaidCodeBlock> {
  SlideCaptureReadinessHandle? _readiness;
  String? _trackedCode;
  bool _reportedFailure = false;

  void _track() {
    if (_trackedCode == widget.code && _readiness != null) return;
    _readiness?.complete();
    _trackedCode = widget.code;
    _reportedFailure = false;
    _readiness = SlideCaptureReadiness.track(
      context,
      label: 'mermaid:${_diagramLabel(widget.code)}',
    );
  }

  /// Ends the wait once the frame that drew the diagram has been laid out.
  ///
  /// The scene is built synchronously while this frame builds, so by the end
  /// of it either the diagram painted or [_fail] has run.
  void _completeAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _reportedFailure) return;
      _readiness?.complete();
      _readiness = null;
    });
  }

  void _fail(Object error) {
    _reportedFailure = true;
    _readiness?.fail('$error');
    _readiness = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _track();
  }

  @override
  void didUpdateWidget(MermaidCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) _track();
  }

  @override
  void dispose() {
    _readiness?.complete();
    _readiness = null;
    super.dispose();
  }

  /// The reason this source cannot be drawn completely, if there is one.
  ///
  /// Checked here rather than left to the renderer, because the renderer
  /// accepts two inputs it cannot draw faithfully.
  Object? _sourceRejection(String source) {
    try {
      checkMermaidSource(source);

      return null;
    } on mermaid.MermaidParseException catch (error) {
      return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    _track();
    _completeAfterFrame();

    if (_sourceRejection(widget.code.trim()) case final rejection?) {
      _fail(rejection);

      return ErrorWidgets.detailed(
        'Unable to render Mermaid diagram',
        '$rejection',
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: MermaidDiagram(
        source: widget.code.trim(),
        theme: _slideDiagramTheme(context),
        errorBuilder: (context, error) {
          _fail(error);

          return ErrorWidgets.detailed(
            'Unable to render Mermaid diagram',
            '$error',
          );
        },
        // A slide shows the diagram its source describes, or says why it
        // cannot. Keeping the last good scene would export a stale drawing.
        keepLastGoodSceneOnError: false,
        semanticNodes: true,
      ),
    );
  }
}

/// A Mermaid theme built from the app's own colours, with no background.
///
/// The slide already painted its background; the diagram draws on top of it.
mermaid.MermaidTheme _slideDiagramTheme(BuildContext context) {
  final theme = MaterialMermaidTheme.fromTheme(Theme.of(context));

  return theme.copyWith(background: const mermaid.Color(0x00000000));
}

/// Names a diagram by its first meaningful line, for capture diagnostics.
String _diagramLabel(String code) {
  for (final line in code.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty && !trimmed.startsWith('%%')) {
      return trimmed.length <= 40 ? trimmed : '${trimmed.substring(0, 39)}…';
    }
  }

  return 'diagram';
}
