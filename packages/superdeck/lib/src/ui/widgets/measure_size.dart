import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

typedef OnMeasureChange =
    void Function(Size size, BoxConstraints parentConstraints);

/// RenderObject that measures size and constraints.
///
/// This implementation follows Flutter best practices for size measurement:
/// - Uses [SchedulerBinding.instance.addPostFrameCallback] to defer callbacks
///   until after the render pipeline completes, preventing layout feedback loops
/// - Coalesces multiple layout passes within a single frame to avoid duplicate
///   notifications
/// - Guards against notifications after the render object detaches, preventing
///   stale callbacks to disposed listeners
/// - Reads [size] directly (safe even when child is null) rather than relying
///   on child?.size
///
/// See also:
/// - The Widget Size Measurement Guide in docs/guides/widget-size-guide.mdx
/// - [SchedulerBinding.addPostFrameCallback] for callback timing
/// - [RenderProxyBox.performLayout] for layout pass integration
class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject({required this.onChange});

  OnMeasureChange onChange;

  // Change detection and reporting: Track last reported size/constraints to
  // determine when a new value should be notified
  Size? _lastReportedSize;
  BoxConstraints? _lastReportedConstraints;

  // Pending state: Store the latest values seen during layout to report
  // in the post-frame callback
  Size? _latestSize;
  BoxConstraints? _latestConstraints;

  // Coalescing flag: Prevents scheduling multiple callbacks within the same frame
  bool _callbackScheduled = false;

  @override
  void performLayout() {
    super.performLayout();

    // Read size directly from the render object (safe even when child is null).
    // This is more reliable than child?.size ?? Size.zero because it reflects
    // the actual laid-out size of this render object.
    final Size newSize = size;
    final BoxConstraints newConstraints = constraints;

    // Update latest values and schedule callback if changed from last report
    if (_lastReportedSize != newSize ||
        _lastReportedConstraints != newConstraints) {
      _latestSize = newSize;
      _latestConstraints = newConstraints;
      _scheduleCallback();
    }
  }

  /// Schedules a post-frame callback to notify listeners of size changes.
  ///
  /// This method implements callback coalescing: if a callback is already
  /// scheduled for the current frame, it does nothing. Multiple layout passes
  /// within a frame will update [_latestSize] and [_latestConstraints] but
  /// only trigger a single notification.
  ///
  /// The callback is deferred until after the frame completes to prevent
  /// "setState() or markNeedsLayout() called during layout" errors.
  void _scheduleCallback() {
    if (_callbackScheduled) return;
    _callbackScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _callbackScheduled = false;

      // Guard against notifications after the render object has been removed
      // from the tree. This prevents stale callbacks to disposed listeners.
      if (!attached) return;

      // Verify we have pending values to report
      final s = _latestSize;
      final c = _latestConstraints;
      if (s == null || c == null) return;

      // Extra safety: check if values actually changed from last report
      // This prevents duplicate notifications if the same values appear again
      if (_lastReportedSize == s && _lastReportedConstraints == c) return;

      // Update tracking and fire callback
      _lastReportedSize = s;
      _lastReportedConstraints = c;
      onChange(s, c);
    });
  }

  @override
  void detach() {
    // Cancel any pending callback when the render object is removed from the tree.
    // This prevents callbacks from firing after disposal.
    _callbackScheduled = false;
    super.detach();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Size>('lastReportedSize', _lastReportedSize),
    );
    properties.add(
      DiagnosticsProperty<BoxConstraints>(
        'lastReportedConstraints',
        _lastReportedConstraints,
      ),
    );
    properties.add(
      FlagProperty(
        'callbackScheduled',
        value: _callbackScheduled,
        ifTrue: 'callback pending',
        ifFalse: 'no callback pending',
      ),
    );
  }
}

/// Widget that measures its child's laid-out size and parent constraints.
///
/// [MeasureSize] wraps a child widget and notifies [onChange] with the child's
/// final [Size] and the parent [BoxConstraints] (constraints applied to this
/// widget) after each frame where they change.
///
/// This widget is useful when you need to know the actual rendered dimensions
/// of a widget after layout completes, such as for:
/// - Positioning overlays or tooltips relative to measured content
/// - Analytics or debugging (tracking widget sizes)
/// - Coordinating layouts across disconnected widget subtrees
///
/// ## When NOT to use MeasureSize
///
/// Consider these built-in alternatives before using [MeasureSize]:
///
/// - **[LayoutBuilder]** - When you need parent constraints (not final size)
/// - **[SizeChangedLayoutNotifier]** - When you only need change notifications
/// - **[AnimatedSize]** - For smooth size transitions
/// - **Custom layout delegates** - When you control both parent and children
/// - **[CompositedTransformFollower]** - For anchoring overlays
///
/// See the Widget Size Measurement Guide (docs/guides/widget-size-guide.mdx)
/// for detailed guidance on when measurement is appropriate.
///
/// ## Implementation Details
///
/// - Notifications are deferred to post-frame callbacks, preventing layout
///   feedback loops
/// - Multiple layout passes within a frame are coalesced into a single
///   notification
/// - Callbacks are not fired after the widget is disposed
/// - The measured size is always available, even when the child is null
///   (reports [Size.zero])
///
/// ## Example
///
/// ```dart
/// class ResizablePanel extends StatefulWidget {
///   @override
///   State<ResizablePanel> createState() => _ResizablePanelState();
/// }
///
/// class _ResizablePanelState extends State<ResizablePanel> {
///   Size? _size;
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         Text('Panel size: ${_size ?? "measuring..."}'),
///         MeasureSize(
///           onChange: (size, parentConstraints) => setState(() => _size = size),
///           child: Container(
///             padding: EdgeInsets.all(16),
///             child: Text('Dynamic content'),
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// See also:
/// - [LayoutBuilder] for accessing parent constraints during build
/// - [SizeChangedLayoutNotifier] for size change notifications without values
/// - The Widget Size Measurement Guide for best practices
class MeasureSize extends SingleChildRenderObjectWidget {
  /// Called when the child size or parent constraints change.
  ///
  /// Receives the laid-out [Size] of the child and the parent [BoxConstraints]
  /// that were applied to this [MeasureSize] widget.
  ///
  /// This callback is invoked after the frame completes, ensuring it's safe
  /// to call [setState] or trigger other state updates without causing layout
  /// feedback loops.
  ///
  /// The callback fires:
  /// - Once on the first layout (establishing initial size)
  /// - Whenever the size or parent constraints change
  /// - At most once per frame (even if layout runs multiple times)
  ///
  /// The callback will NOT fire:
  /// - After the widget is disposed
  /// - When the size and parent constraints remain unchanged
  final OnMeasureChange onChange;

  /// Creates a widget that measures its child's size and constraints.
  ///
  /// The [onChange] callback is required and will be invoked after each frame
  /// where the child's size or constraints change.
  ///
  /// The [child] is required. If you need to conditionally render content,
  /// wrap [MeasureSize] in a conditional or provide a [SizedBox.shrink] as
  /// the child (which will report [Size.zero]).
  const MeasureSize({
    super.key,
    required this.onChange,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange: onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    final measureRenderObject = renderObject as _MeasureSizeRenderObject;
    measureRenderObject.onChange = onChange;
  }
}
