import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

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

/// Filename of the first-run default deck, born in `~/Documents/SuperDeck/`.
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
///   app's own writes (by comparing a content hash) so auto-save doesn't loop.
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

  String? _boundPath;
  DeckBindingStatus _status = DeckBindingStatus.bound;
  String _content = kStarterDeckMarkdown;
  String? _warning;

  /// Hash of the content last read from / written to disk. Auto-saves that
  /// match it (and watcher events whose on-disk content matches it) are the
  /// app's own writes and are filtered out.
  String _lastSyncedHash = generateValueHash(kStarterDeckMarkdown);

  Timer? _debounce;
  StreamSubscription<void>? _watchSub;
  bool _disposed = false;

  /// Absolute path of the bound file, or `null` before [initialize].
  String? get boundPath => _boundPath;

  /// The bound file's display name (e.g. `deck.md`), or `Untitled` if unbound
  /// with no path.
  String get fileName =>
      _boundPath == null ? 'Untitled' : p.basename(_boundPath!);

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
  /// deck in `~/Documents/SuperDeck/` (created on first run).
  Future<void> initialize() async {
    final remembered = await _settings.lastOpenedDeckPath();
    if (remembered != null && await _store.exists(remembered)) {
      try {
        final content = await _store.read(remembered);
        _bindState(remembered, content);
        await _rememberAndWatch(remembered);
        return;
      } on DeckFileReadException {
        // Fall through to the default deck.
      }
    }
    final (path, content) = await _ensureDefaultDeck();
    _bindState(path, content);
    await _rememberAndWatch(path);
  }

  /// Creates `<name>.md` in the decks folder, seeds it with the starter
  /// template, and rebinds the editor to it.
  ///
  /// Throws [DeckNameCollisionException] on a name clash so the dialog can
  /// re-prompt.
  Future<void> newDeck(String name) async {
    final path = await _store.createDeck(name, content: kStarterDeckMarkdown);
    await _rebind(path, kStarterDeckMarkdown);
  }

  /// Opens a `.md` from anywhere on disk (native picker) and rebinds.
  ///
  /// A cancelled picker is a no-op. A read failure surfaces a warning and keeps
  /// the current file bound.
  Future<void> openDeck() async {
    final path = await _store.pickDeckFile();
    if (path == null) return;
    try {
      final content = await _store.read(path);
      await _rebind(path, content);
    } on DeckFileReadException {
      _warning =
          'Could not open "${p.basename(path)}". '
          'Keeping the current deck.';
      _notify();
    }
  }

  /// Receives every editor edit. Debounces a write to the bound file; skips
  /// while unbound (content is retained in memory) and skips echoes of our own
  /// writes/reloads.
  void handleEditorChange(String markdown) {
    _content = markdown;
    if (_status != DeckBindingStatus.bound || _boundPath == null) return;
    if (generateValueHash(markdown) == _lastSyncedHash) return;

    _debounce?.cancel();
    _debounce = Timer(_autoSaveDebounce, () => _flushSave(markdown));
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    unawaited(_watchSub?.cancel());
    super.dispose();
  }

  Future<void> _flushSave(String markdown) async {
    final path = _boundPath;
    if (_status != DeckBindingStatus.bound || path == null) return;
    // Set the synced hash *before* writing so the watcher event our write
    // triggers is recognised as a self-write and ignored.
    _lastSyncedHash = generateValueHash(markdown);
    try {
      await _store.write(path, markdown);
    } catch (_) {
      // Best-effort auto-save; a subsequent edit will retry. If the file is
      // gone the watcher will unbind and warn.
    }
  }

  Future<void> _rebind(String path, String content) async {
    _bindState(path, content);
    _editor?.replaceMarkdown(content);
    await _rememberAndWatch(path);
  }

  /// Updates in-memory binding state (path, content, hash, status) without any
  /// I/O or editor/side effects.
  void _bindState(String path, String content) {
    _debounce?.cancel();
    _boundPath = path;
    _content = content;
    _lastSyncedHash = generateValueHash(content);
    _status = DeckBindingStatus.bound;
    _warning = null;
  }

  Future<void> _rememberAndWatch(String path) async {
    await _settings.setLastOpenedDeckPath(path);
    _startWatching(path);
    _notify();
  }

  void _startWatching(String path) {
    unawaited(_watchSub?.cancel());
    _watchSub = _store
        .watch(path)
        .listen((_) => _onFileChanged(), onError: (_) {});
  }

  Future<void> _onFileChanged() async {
    final path = _boundPath;
    if (path == null || _status != DeckBindingStatus.bound) return;

    if (!await _store.exists(path)) {
      _handleFileLost();
      return;
    }

    String diskContent;
    try {
      diskContent = await _store.read(path);
    } on DeckFileReadException {
      _handleFileLost();
      return;
    }

    // Self-write filter: our own auto-save produced this content.
    if (generateValueHash(diskContent) == _lastSyncedHash) return;

    // External change → external wins → reload into the editor. Cancel any
    // pending auto-save so a stale in-flight edit can't clobber the new content.
    _debounce?.cancel();
    _content = diskContent;
    _lastSyncedHash = generateValueHash(diskContent);
    _editor?.replaceMarkdown(diskContent);
    _notify();
  }

  void _handleFileLost() {
    unawaited(_watchSub?.cancel());
    _watchSub = null;
    _debounce?.cancel();
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
      try {
        return (path, await _store.read(path));
      } on DeckFileReadException {
        // Recreate below if it can't be read.
      }
    }
    await _store.write(path, kStarterDeckMarkdown);
    return (path, kStarterDeckMarkdown);
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}
