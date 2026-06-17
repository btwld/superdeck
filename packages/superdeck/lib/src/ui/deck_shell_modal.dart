import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Provides app-shell modal presentation for deck actions.
///
/// This is intentionally lighter than route integration: actions can place a
/// transient surface above the full SuperDeck shell without owning navigation.
abstract final class DeckShellModal {
  static DeckShellModalController? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_DeckShellModalScope>()
        ?.controller;
  }
}

final class DeckShellModalController {
  final Signal<List<DeckShellModalEntry>> _entries = signal(const []);

  List<DeckShellModalEntry> get entries => List.unmodifiable(_entries.value);

  DeckShellModalEntry show({required WidgetBuilder builder}) {
    late final DeckShellModalEntry entry;
    entry = DeckShellModalEntry._(
      builder: builder,
      onClose: () => _remove(entry),
    );
    _entries.value = [..._entries.value, entry];

    return entry;
  }

  void _remove(DeckShellModalEntry entry) {
    final next = _entries.value.where((e) => e != entry).toList();
    if (next.length == _entries.value.length) return;

    _entries.value = next;
  }

  void dispose() {
    for (final entry in _entries.value) {
      entry._dispose();
    }
    _entries.value = const [];
    _entries.dispose();
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
    _isClosed = true;
    _complete();
  }

  void _complete() {
    if (!_closed.isCompleted) {
      _closed.complete();
    }
  }

  void close() {
    if (_isClosed) return;

    _isClosed = true;
    _onClose();
    _complete();
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
    _controller = DeckShellModalController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DeckShellModalScope(
      controller: _controller,
      child: Watch(
        (context) => Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            for (final entry in _controller.entries)
              Positioned.fill(child: _DeckShellModalEntryView(entry: entry)),
          ],
        ),
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
