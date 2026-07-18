import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

/// A text field that commits only on submit or focus-loss, reverting to [value]
/// when the input can't be parsed.
///
/// [value] is the source of truth: [format] renders it into the field, and
/// external changes to it are pulled back into the field unless the user is
/// mid-edit. On commit, [parse] converts the field text to a value — or null to
/// reject and revert. A non-null result is normalized back through [format] and
/// reported via [onChanged] when it differs from [value].
///
/// This owns only the commit/sync logic; callers wrap it with their own label
/// and layout.
class CommittedTextField<T> extends StatefulWidget {
  const CommittedTextField({
    super.key,
    required this.value,
    required this.format,
    required this.parse,
    required this.onChanged,
    this.leading,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
  });

  final T value;
  final String Function(T value) format;
  final T? Function(String text) parse;
  final ValueChanged<T> onChanged;
  final Widget? leading;
  final RemixTextFieldStyler? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<CommittedTextField<T>> createState() => _CommittedTextFieldState<T>();
}

class _CommittedTextFieldState<T> extends State<CommittedTextField<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.format(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(CommittedTextField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pull external value changes into the field, unless the user is mid-edit.
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = widget.format(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  /// Parses the field and either reports a normalized value or reverts the field
  /// to [CommittedTextField.value].
  void _commit() {
    final parsed = widget.parse(_controller.text);
    if (parsed == null) {
      _controller.text = widget.format(widget.value);
      return;
    }
    _controller.text = widget.format(parsed);
    if (parsed != widget.value) widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return HeroTextField(
      fullWidth: true,
      controller: _controller,
      focusNode: _focusNode,
      style: widget.style,
      leading: widget.leading,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onSubmitted: (_) => _commit(),
    );
  }
}
