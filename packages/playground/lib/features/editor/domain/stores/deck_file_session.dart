import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../../core/result.dart';
import '../files/deck_file.dart';
import '../files/deck_file_repository.dart';
import 'deck_document_store.dart';

/// Markdown used to seed the first deck and every newly created deck.
const kStarterDeckMarkdown = '''---

# Title
## Subtitle

---
''';

/// Whether the document is currently persisted to an active deck file.
enum DeckBindingStatus {
  /// Document changes are debounced and written to the active file.
  bound,

  /// The active file disappeared or became unreadable. The document remains
  /// editable in memory until the user creates or opens another deck.
  unbound,
}

/// Synchronizes one [DeckDocumentStore] with an active deck file.
///
/// The session deliberately owns no Markdown itself. It only tracks the
/// binding and the last content synchronized with disk so that local edits,
/// watcher events, deck changes, and file loss remain race-safe.
class DeckFileSession extends ChangeNotifier {
  final DeckFileRepository _repository;
  final DeckDocumentStore _documentStore;
  final Duration _autoSaveDebounce;

  DeckFileReference? _boundDeck;
  DeckBindingStatus _status = DeckBindingStatus.bound;
  String? _warning;

  /// Content most recently observed as synchronized with the active file.
  String _lastSyncedContent;

  Timer? _debounce;
  StreamSubscription<DeckFileEvent>? _watchSubscription;
  Future<void> _saveQueue = Future<void>.value();
  ({int epoch, DeckFileReference reference, String markdown})? _activeWrite;
  int _bindingEpoch = 0;
  bool _disposed = false;

  DeckFileSession({
    required DeckFileSnapshot initialSnapshot,
    required DeckFileRepository repository,
    required DeckDocumentStore documentStore,
    Duration autoSaveDebounce = const Duration(milliseconds: 400),
  }) : _repository = repository,
       _documentStore = documentStore,
       _autoSaveDebounce = autoSaveDebounce,
       _boundDeck = initialSnapshot.reference,
       _lastSyncedContent = initialSnapshot.markdown {
    if (documentStore.markdown != initialSnapshot.markdown) {
      documentStore.replaceMarkdown(initialSnapshot.markdown);
    }
    _documentStore.addListener(_onDocumentChanged);
    _startWatching(initialSnapshot.reference, _bindingEpoch);
  }

  /// The bound file path, retained after loss so its name can still be shown.
  String? get boundPath => _boundDeck?.path;

  /// Filename for the header, or `Untitled` before a deck is bound.
  String get fileName =>
      boundPath == null ? 'Untitled' : p.basename(boundPath!);

  /// Current persistence binding state.
  DeckBindingStatus get status => _status;

  /// Whether local document changes are currently auto-saved.
  bool get isBound => _status == DeckBindingStatus.bound;

  /// A user-facing persistence warning, if the latest operation failed.
  String? get warning => _warning;

  /// Creates a new app-owned deck after flushing the current document.
  ///
  /// Name collisions are returned so the dialog can display them inline.
  Future<Result<void>> createDeck(String name) async {
    if (!await flushPendingSave()) {
      return Result.error(
        DeckFileWriteException(
          boundPath ?? '<in-memory deck>',
          StateError('Could not save the current deck.'),
        ),
      );
    }

    final created = await _repository.createDeck(
      name: name,
      markdown: kStarterDeckMarkdown,
    );
    switch (created) {
      case Failure(:final error):
        return Result.error(error);
      case Ok(value: final DeckFileSnapshot value):
        if (_disposed) {
          await _repository.releaseDeck(value.reference);
          return Result.error(
            DeckFileWriteException(
              value.reference.path,
              StateError('The deck session has been disposed.'),
            ),
          );
        }
        await _rebind(value);
        return const Result.ok(null);
    }
  }

  /// Opens a picked deck after flushing the current document.
  ///
  /// Cancellation is a no-op. Failures keep the current binding and surface a
  /// warning in the header.
  Future<void> openDeck() async {
    if (!await flushPendingSave()) return;

    final picked = await _repository.pickDeck();
    switch (picked) {
      case Failure():
        _warning = 'Could not open a deck. Keeping the current deck.';
        _notify();
      case Ok(value: null):
        return;
      case Ok(value: final DeckFileSnapshot value):
        if (_disposed) {
          await _repository.releaseDeck(value.reference);
          return;
        }
        await _rebind(value);
    }
  }

  /// Persists all edits made before this method completes.
  ///
  /// Returns `false` when the final write fails, so a lifecycle exit request
  /// can be cancelled while the latest Markdown remains in memory.
  Future<bool> flushPendingSave() async {
    while (true) {
      _debounce?.cancel();
      _debounce = null;
      await _saveQueue;

      final reference = _boundDeck;
      if (_disposed ||
          _status != DeckBindingStatus.bound ||
          reference == null) {
        return !_disposed;
      }
      final markdown = _documentStore.markdown;
      if (markdown == _lastSyncedContent) return true;
      if (!await _queueSave(reference, _bindingEpoch, markdown)) return false;
      // The document can change while its write is in flight. Keep flushing
      // until the latest snapshot, rather than the first one, is on disk.
    }
  }

  void _onDocumentChanged() {
    final reference = _boundDeck;
    if (_disposed || _status != DeckBindingStatus.bound || reference == null) {
      return;
    }

    final markdown = _documentStore.markdown;
    _debounce?.cancel();
    if (markdown == _lastSyncedContent) return;

    final epoch = _bindingEpoch;
    _debounce = Timer(_autoSaveDebounce, () {
      _debounce = null;
      unawaited(_queueSave(reference, epoch, markdown));
    });
  }

  Future<bool> _queueSave(
    DeckFileReference reference,
    int epoch,
    String markdown,
  ) {
    final operation = _saveQueue.then(
      (_) => _write(reference, epoch, markdown),
    );
    _saveQueue = operation.then<void>((_) {});
    return operation;
  }

  Future<bool> _write(
    DeckFileReference reference,
    int epoch,
    String markdown,
  ) async {
    if (!_isCurrentBinding(reference, epoch)) return false;

    final activeWrite = (
      epoch: epoch,
      reference: reference,
      markdown: markdown,
    );
    _activeWrite = activeWrite;
    try {
      final result = await _repository.writeDeck(reference, markdown);
      if (!_isCurrentBinding(reference, epoch)) return false;
      switch (result) {
        case Ok():
          _lastSyncedContent = markdown;
          return true;
        case Failure():
          _warning =
              'Could not save "$fileName". Your latest edits are in memory.';
          _notify();
          return false;
      }
    } finally {
      if (_activeWrite == activeWrite) _activeWrite = null;
    }
  }

  Future<void> _rebind(DeckFileSnapshot snapshot) async {
    final previous = _boundDeck;
    _debounce?.cancel();
    _debounce = null;
    _bindingEpoch++;
    unawaited(_watchSubscription?.cancel());
    _watchSubscription = null;

    _boundDeck = snapshot.reference;
    _lastSyncedContent = snapshot.markdown;
    _status = DeckBindingStatus.bound;
    _warning = null;
    _documentStore.replaceMarkdown(snapshot.markdown);

    if (previous != null && previous != snapshot.reference) {
      await _repository.releaseDeck(previous);
    }
    if (_disposed) {
      await _repository.releaseDeck(snapshot.reference);
      return;
    }
    _startWatching(snapshot.reference, _bindingEpoch);
    _notify();
  }

  void _startWatching(DeckFileReference reference, int epoch) {
    _watchSubscription = _repository
        .watchDeck(reference)
        .listen(
          (event) => _onFileEvent(reference, epoch, event),
          onError: (_) => _handleFileUnavailable(reference, epoch),
        );
  }

  void _onFileEvent(
    DeckFileReference reference,
    int epoch,
    DeckFileEvent event,
  ) {
    if (!_isCurrentBinding(reference, epoch)) return;
    switch (event) {
      case DeckFileUnavailable():
        _handleFileUnavailable(reference, epoch);
      case DeckFileChanged(:final markdown):
        _handleExternalChange(reference, epoch, markdown);
    }
  }

  void _handleExternalChange(
    DeckFileReference reference,
    int epoch,
    String markdown,
  ) {
    if (!_isCurrentBinding(reference, epoch)) return;

    final activeWrite = _activeWrite;
    final hasActiveWrite =
        activeWrite != null &&
        activeWrite.epoch == epoch &&
        activeWrite.reference == reference;
    if (markdown == _lastSyncedContent ||
        (hasActiveWrite && activeWrite.markdown == markdown)) {
      return;
    }

    // External content wins. If a local write is already in flight, queue the
    // external content after it so the old local content cannot be final on
    // disk.
    _debounce?.cancel();
    _debounce = null;
    _lastSyncedContent = markdown;
    _documentStore.replaceMarkdown(markdown);
    if (hasActiveWrite) {
      unawaited(_queueSave(reference, epoch, markdown));
    }
    _notify();
  }

  void _handleFileUnavailable(DeckFileReference reference, int epoch) {
    if (!_isCurrentBinding(reference, epoch)) return;

    unawaited(_watchSubscription?.cancel());
    _watchSubscription = null;
    _debounce?.cancel();
    _debounce = null;
    _bindingEpoch++;
    _status = DeckBindingStatus.unbound;
    _warning =
        'The file "$fileName" is no longer on disk. '
        'Your work is kept here — use New or Open to save it to a file.';
    unawaited(_repository.releaseDeck(reference));
    _notify();
  }

  bool _isCurrentBinding(DeckFileReference reference, int epoch) {
    return !_disposed &&
        _status == DeckBindingStatus.bound &&
        _boundDeck == reference &&
        _bindingEpoch == epoch;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _bindingEpoch++;
    _documentStore.removeListener(_onDocumentChanged);
    _debounce?.cancel();
    unawaited(_watchSubscription?.cancel());
    final reference = _boundDeck;
    if (reference != null) unawaited(_repository.releaseDeck(reference));
    super.dispose();
  }
}
