import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../../core/data/data_sources/app_settings_store.dart';
import '../../../../core/data/data_sources/deck_file_store.dart';
import '../../utils/markdown_editor.dart';

/// Markdown a new (or first-run default) deck is seeded with, so the live
/// preview is never blank.
const kStarterDeckMarkdown = '''---

# Title
## Subtitle

---
''';

/// Filename of the first-run default deck in SuperDeck's app storage.
const _defaultDeckFileName = 'untitled.md';

/// Whether the editor is currently backed by a real file on disk.
enum DeckBindingStatus {
  /// Edits auto-save to [DeckFileController.boundPath].
  bound,

  /// The bound file was deleted/moved: edits are kept in memory only, and the
  /// user is warned to `New`/`Open` to persist again.
  unbound,
}

/// Binds the editor to a real `.md` file and keeps them in sync.
///
/// Responsibilities:
/// - **Auto-save**: debounced writes of every edit back to [boundPath]; there
///   is no manual save and no dirty flag.
/// - **Watch + self-write filtering**: watches the bound file and ignores the
///   app's own writes (by comparing the content it last synced) so auto-save
///   doesn't loop.
/// - **External wins**: an external change to the bound file auto-reloads into
///   the editor.
/// - **Unbind on loss**: a deleted/moved file stops auto-save, keeps the
///   in-memory content, and surfaces a warning — never resurrecting the file.
/// - **New/Open/launch**: create a named deck, open one from anywhere, and
///   reopen the last-opened file on launch (falling back to a default deck).
///
/// The editor document itself lives in `TextEditorController`; this controller
/// drives it through the [MarkdownEditor] port for reloads and receives edits
/// through [handleEditorChange].
class DeckFileController extends ChangeNotifier {
  DeckFileController({
    required DeckFileStore store,
    required AppSettingsStore settings,
    Duration autoSaveDebounce = const Duration(milliseconds: 400),
  }) : _store = store,
       _settings = settings,
       _autoSaveDebounce = autoSaveDebounce;

  final DeckFileStore _store;
  final AppSettingsStore _settings;
  final Duration _autoSaveDebounce;

  MarkdownEditor? _editor;

  DeckFileReference? _boundDeck;
  DeckBindingStatus _status = DeckBindingStatus.bound;
  String _content = kStarterDeckMarkdown;
  String? _warning;

  /// The content last read from / written to disk. Auto-saves that match it
  /// (and watcher events whose on-disk content matches it) are the app's own
  /// writes and are filtered out. Compared by value — a hash would risk a
  /// collision silently dropping a genuine external edit.
  String _lastSyncedContent = kStarterDeckMarkdown;

  Timer? _debounce;
  StreamSubscription<void>? _watchSub;
  Future<void> _saveQueue = Future<void>.value();
  ({int epoch, String path, String content})? _activeWrite;
  int _bindingEpoch = 0;
  bool _disposed = false;

  /// Absolute path of the bound file, or `null` before [initialize].
  String? get boundPath => _boundDeck?.path;

  /// The bound file's display name (e.g. `deck.md`), or `Untitled` if unbound
  /// with no path.
  String get fileName =>
      boundPath == null ? 'Untitled' : p.basename(boundPath!);

  /// Current binding status.
  DeckBindingStatus get status => _status;

  /// True while edits auto-save to disk.
  bool get isBound => _status == DeckBindingStatus.bound;

  /// The latest markdown (kept even while [DeckBindingStatus.unbound]).
  String get content => _content;

  /// A user-facing warning (e.g. the bound file vanished, or an open failed),
  /// or `null` when everything is healthy.
  String? get warning => _warning;

  /// Wires the editor this controller drives on reloads. Called once, right
  /// after the editor is built with [content] as its initial text.
  void attachEditor(MarkdownEditor editor) => _editor = editor;

  /// Resolves the deck to open on launch and binds to it:
  /// the last-opened file if it still exists and reads, otherwise a default
  /// deck in SuperDeck's app storage (created on first run).
  Future<void> initialize() async {
    final remembered = await _settings.lastOpenedDeck();
    if (_disposed) return;
    if (remembered != null) {
      final loaded = await _loadDeck(remembered);
      if (_disposed) return;
      if (loaded != null) {
        await _rebind(loaded.reference, loaded.content);
        return;
      }
    }
    final (path, content) = await _ensureDefaultDeck();
    if (_disposed) return;
    await _rebind(DeckFileReference(path: path), content);
  }

  /// Creates `<name>.md` in the decks folder, seeds it with the starter
  /// template, and rebinds the editor to it.
  ///
  /// Throws [DeckNameCollisionException] on a name clash so the dialog can
  /// re-prompt.
  Future<void> newDeck(String name) async {
    if (!await flushPendingSave()) {
      throw StateError('Could not save the current deck.');
    }
    final path = await _store.createDeck(name, content: kStarterDeckMarkdown);
    await _rebind(DeckFileReference(path: path), kStarterDeckMarkdown);
  }

  /// Opens a `.md` from anywhere on disk (native picker) and rebinds.
  ///
  /// A cancelled picker is a no-op. A read failure surfaces a warning and keeps
  /// the current file bound.
  Future<void> openDeck() async {
    if (!await flushPendingSave()) return;
    DeckFileReference? picked;
    try {
      picked = await _store.pickDeckFile();
    } catch (_) {
      _warning = 'Could not open a deck. Keeping the current deck.';
      _notify();
      return;
    }
    if (picked == null || _disposed) return;
    final loaded = await _loadDeck(picked);
    if (_disposed) return;
    if (loaded != null) {
      await _rebind(loaded.reference, loaded.content);
      return;
    }
    _warning =
        'Could not open "${p.basename(picked.path)}". '
        'Keeping the current deck.';
    _notify();
  }

  /// Receives every editor edit. Debounces a write to the bound file; skips
  /// while unbound (content is retained in memory) and skips echoes of our own
  /// writes/reloads.
  void handleEditorChange(String markdown) {
    _content = markdown;
    final path = boundPath;
    if (_status != DeckBindingStatus.bound || path == null) return;

    // Cancel any pending save first: if the edit reverted back to the synced
    // content within the debounce window, a stale save must not still fire.
    _debounce?.cancel();
    if (markdown == _lastSyncedContent) return;
    final epoch = _bindingEpoch;
    _debounce = Timer(_autoSaveDebounce, () {
      _debounce = null;
      unawaited(_queueSave(path, epoch, markdown));
    });
  }

  /// Persists all edits made before this method completes.
  ///
  /// Returns `false` when the final write fails, allowing an exit request to
  /// be cancelled while the latest content remains in memory.
  Future<bool> flushPendingSave() async {
    while (true) {
      _debounce?.cancel();
      _debounce = null;
      await _saveQueue;

      final path = boundPath;
      if (_disposed || _status != DeckBindingStatus.bound || path == null) {
        return !_disposed;
      }
      final markdown = _content;
      if (markdown == _lastSyncedContent) return true;
      if (!await _queueSave(path, _bindingEpoch, markdown)) return false;
      // Content can change while a write is in flight. Loop until the latest
      // editor value, not merely the first snapshot, is confirmed on disk.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _bindingEpoch++;
    _debounce?.cancel();
    unawaited(_watchSub?.cancel());
    final boundDeck = _boundDeck;
    if (boundDeck != null) unawaited(_stopAccessing(boundDeck));
    super.dispose();
  }

  Future<bool> _queueSave(String path, int epoch, String markdown) {
    final operation = _saveQueue.then((_) => _write(path, epoch, markdown));
    _saveQueue = operation.then<void>((_) {});
    return operation;
  }

  Future<bool> _write(String path, int epoch, String markdown) async {
    if (!_isCurrentBinding(path, epoch)) return false;

    final activeWrite = (epoch: epoch, path: path, content: markdown);
    _activeWrite = activeWrite;
    try {
      await _store.write(path, markdown);
      if (!_isCurrentBinding(path, epoch)) return false;
      _lastSyncedContent = markdown;
      return true;
    } catch (_) {
      if (_isCurrentBinding(path, epoch)) {
        _warning =
            'Could not save "$fileName". Your latest edits are in memory.';
        _notify();
      }
      return false;
    } finally {
      if (_activeWrite == activeWrite) _activeWrite = null;
    }
  }

  Future<void> _rebind(DeckFileReference reference, String content) async {
    if (_disposed) {
      await _stopAccessing(reference);
      return;
    }
    final previous = _boundDeck;
    _bindState(reference, content);
    _editor?.replaceMarkdown(content);
    if (previous?.bookmark != null &&
        previous!.bookmark != reference.bookmark) {
      await _stopAccessing(previous);
    }
    await _rememberAndWatch(reference, _bindingEpoch);
  }

  /// Updates in-memory binding state (path, content, synced marker, status)
  /// without any I/O or editor/side effects.
  void _bindState(DeckFileReference reference, String content) {
    _debounce?.cancel();
    _bindingEpoch++;
    _boundDeck = reference;
    _content = content;
    _lastSyncedContent = content;
    _status = DeckBindingStatus.bound;
    _warning = null;
  }

  Future<void> _rememberAndWatch(DeckFileReference reference, int epoch) async {
    try {
      await _settings.setLastOpenedDeck(reference);
    } catch (_) {
      // Remembering the path is a launch convenience; it must not break the
      // active binding when the app-support settings file is unavailable.
    }
    final path = reference.path;
    if (!_isCurrentBinding(path, epoch)) return;
    _startWatching(path, epoch);
    _notify();
  }

  void _startWatching(String path, int epoch) {
    unawaited(_watchSub?.cancel());
    _watchSub = _store
        .watch(path)
        .listen((_) => _onFileChanged(path, epoch), onError: (_) {});
  }

  Future<void> _onFileChanged(String path, int epoch) async {
    if (!_isCurrentBinding(path, epoch)) return;
    if (!await _store.exists(path)) {
      _handleFileLost(path, epoch);
      return;
    }
    if (!_isCurrentBinding(path, epoch)) return;

    String diskContent;
    try {
      diskContent = await _store.read(path);
    } on DeckFileReadException {
      _handleFileLost(path, epoch);
      return;
    }
    if (!_isCurrentBinding(path, epoch)) return;

    // Self-write filter: our own auto-save produced this content.
    final activeWrite = _activeWrite;
    final hasActiveWrite =
        activeWrite != null &&
        activeWrite.epoch == epoch &&
        activeWrite.path == path;
    if (diskContent == _lastSyncedContent ||
        (hasActiveWrite && activeWrite.content == diskContent)) {
      return;
    }

    // External change → external wins → reload into the editor. Cancel a
    // pending save, and if a write is already in flight, queue the external
    // content behind it so that older write cannot become the final disk value.
    _debounce?.cancel();
    _content = diskContent;
    _lastSyncedContent = diskContent;
    _editor?.replaceMarkdown(diskContent);
    if (hasActiveWrite) {
      unawaited(_queueSave(path, epoch, diskContent));
    }
    _notify();
  }

  void _handleFileLost(String path, int epoch) {
    if (!_isCurrentBinding(path, epoch)) return;
    unawaited(_watchSub?.cancel());
    _watchSub = null;
    _debounce?.cancel();
    final boundDeck = _boundDeck;
    if (boundDeck != null) unawaited(_stopAccessing(boundDeck));
    _bindingEpoch++;
    _status = DeckBindingStatus.unbound;
    _warning =
        'The file "$fileName" is no longer on disk. '
        'Your work is kept here — use New or Open to save it to a file.';
    _notify();
  }

  Future<(String, String)> _ensureDefaultDeck() async {
    final dir = await _store.decksDirectoryPath();
    final path = p.join(dir, _defaultDeckFileName);
    if (await _store.exists(path)) {
      return (path, await _store.read(path));
    }
    await _store.write(path, kStarterDeckMarkdown);
    return (path, kStarterDeckMarkdown);
  }

  Future<({DeckFileReference reference, String content})?> _loadDeck(
    DeckFileReference reference,
  ) async {
    DeckFileReference? accessed;
    var keepAccess = false;
    try {
      accessed = await _store.startAccessing(reference);
      if (_disposed || !await _store.exists(accessed.path)) return null;
      if (_disposed) return null;
      final content = await _store.read(accessed.path);
      if (_disposed) return null;
      keepAccess = true;
      return (reference: accessed, content: content);
    } on DeckFileAccessException {
      return null;
    } on DeckFileReadException {
      return null;
    } finally {
      if (!keepAccess && accessed != null) {
        await _stopAccessing(accessed);
      }
    }
  }

  Future<void> _stopAccessing(DeckFileReference reference) async {
    try {
      await _store.stopAccessing(reference);
    } catch (_) {
      // Access is best-effort cleanup. The binding and in-memory content must
      // remain usable even if the platform cannot release an already-lost URL.
    }
  }

  bool _isCurrentBinding(String path, int epoch) {
    return !_disposed &&
        _status == DeckBindingStatus.bound &&
        boundPath == path &&
        _bindingEpoch == epoch;
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}
