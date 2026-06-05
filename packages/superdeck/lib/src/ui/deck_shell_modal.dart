import 'dart:async';

import 'package:flutter/widgets.dart';

/// Provides app-shell modal presentation for deck actions.
///
/// This is intentionally lighter than route integration: actions can place a
/// transient surface above the full SuperDeck shell without owning navigation.
abstract final class DeckShellModal {
  static DeckShellModalController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DeckShellModalScope>()
        ?.controller;
  }
}

final class DeckShellModalController extends ChangeNotifier {
  final List<DeckShellModalEntry> _entries = [];

  List<DeckShellModalEntry> get entries => List.unmodifiable(_entries);

  DeckShellModalEntry show({required WidgetBuilder builder}) {
    late final DeckShellModalEntry entry;
    entry = DeckShellModalEntry._(
      builder: builder,
      onClose: () => _remove(entry),
    );
    _entries.add(entry);
    notifyListeners();

    return entry;
  }

  void _remove(DeckShellModalEntry entry) {
    if (!_entries.remove(entry)) return;

    notifyListeners();
  }

  @override
  void dispose() {
    for (final entry in List<DeckShellModalEntry>.of(_entries)) {
      entry._dispose();
    }
    _entries.clear();
    super.dispose();
  }
}

final class DeckShellModalEntry {
  final WidgetBuilder builder;
  final VoidCallback _onClose;
  final Completer<void> _closed = Completer<void>();
  bool _isClosed = false;

  DeckShellModalEntry._({required this.builder, required VoidCallback onClose})
    : _onClose = onClose;

  Future<void> get closed => _closed.future;

  void _dispose() {
    if (_closed.isCompleted) return;

    _closed.complete();
  }

  void close() {
    if (_isClosed) return;

    _isClosed = true;
    _onClose();
    if (!_closed.isCompleted) {
      _closed.complete();
    }
  }
}

class DeckShellModalHost extends StatefulWidget {
  const DeckShellModalHost({super.key, required this.child});

  final Widget child;

  @override
  State<DeckShellModalHost> createState() => _DeckShellModalHostState();
}

class _DeckShellModalHostState extends State<DeckShellModalHost> {
  late final DeckShellModalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DeckShellModalController()..addListener(_handleModalChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleModalChanged)
      ..dispose();
    super.dispose();
  }

  void _handleModalChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _DeckShellModalScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          for (final entry in _controller.entries)
            Positioned.fill(child: _DeckShellModalEntryView(entry: entry)),
        ],
      ),
    );
  }
}

class _DeckShellModalEntryView extends StatelessWidget {
  const _DeckShellModalEntryView({required this.entry});

  final DeckShellModalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: entry.builder);
  }
}

class _DeckShellModalScope extends InheritedWidget {
  const _DeckShellModalScope({required this.controller, required super.child});

  final DeckShellModalController controller;

  @override
  bool updateShouldNotify(_DeckShellModalScope oldWidget) {
    return oldWidget.controller != controller;
  }
}
