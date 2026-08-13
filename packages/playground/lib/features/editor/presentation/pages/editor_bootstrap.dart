import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/result.dart';
import '../../../ai/quick_agent/domain/commands/generate_deck_command.dart';
import '../../domain/files/deck_file.dart';
import '../../domain/files/deck_file_repository.dart';
import '../../domain/stores/deck_document_store.dart';
import '../../domain/stores/deck_file_session.dart';
import '../../domain/stores/editor_store.dart';
import '../../utils/text_editor_controller.dart';
import 'editor_page.dart';

/// Resolves the initial file-backed deck before the editor mounts.
///
/// The repository performs all bootstrap I/O. Once it returns a snapshot, this
/// widget scopes the document store, synchronization session, editor controller,
/// and generation command to the editor route.
class EditorBootstrap extends StatefulWidget {
  const EditorBootstrap({super.key});

  @override
  State<EditorBootstrap> createState() => _EditorBootstrapState();
}

class _EditorBootstrapState extends State<EditorBootstrap> {
  late final DeckFileRepository _repository;
  late final AppLifecycleListener _lifecycleListener;
  late Future<Result<DeckFileSnapshot>> _initialDeck;

  DeckDocumentStore? _documentStore;
  DeckFileSession? _fileSession;

  @override
  void initState() {
    super.initState();
    _repository = context.read<DeckFileRepository>();
    _initialDeck = _loadInitialDeck();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _handleExitRequested,
    );
  }

  Future<AppExitResponse> _handleExitRequested() async {
    final session = _fileSession;
    if (session == null) return AppExitResponse.exit;
    return await session.flushPendingSave()
        ? AppExitResponse.exit
        : AppExitResponse.cancel;
  }

  Widget _buildEditor(DeckFileSnapshot snapshot) {
    final documentStore = _documentStore ??= DeckDocumentStore(
      markdown: snapshot.markdown,
    );
    final fileSession = _fileSession ??= DeckFileSession(
      initialSnapshot: snapshot,
      repository: _repository,
      documentStore: documentStore,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeckDocumentStore>.value(value: documentStore),
        ChangeNotifierProvider<DeckFileSession>.value(value: fileSession),
        ChangeNotifierProvider(create: (_) => EditorStore()),
        Provider<TextEditorController>(
          lazy: false,
          create: (ctx) => TextEditorController(
            editorStore: ctx.read<EditorStore>(),
            deckLoader: ctx.read<MemoryDeckLoader>(),
            documentStore: ctx.read<DeckDocumentStore>(),
          ),
          dispose: (_, controller) => controller.dispose(),
        ),
        ListenableProvider<GenerateDeckCommand>(
          create: (ctx) => GenerateDeckCommand(
            documentStore: ctx.read<DeckDocumentStore>(),
            customizationStore: ctx.read<DeckCustomizationStore>(),
            deckLoader: ctx.read<MemoryDeckLoader>(),
            assetCacheStore: ctx.read(),
          ),
          dispose: (_, command) => command.dispose(),
        ),
      ],
      child: const EditorPage(),
    );
  }

  Widget _buildFailure(Object error) {
    return _BootstrapMessage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not open the decks folder.\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: $muted.resolve(context)),
          ),
          const SizedBox(height: 16),
          HeroButton(
            label: 'Try again',
            leadingIcon: Icons.refresh,
            onPressed: _retry,
          ),
        ],
      ),
    );
  }

  Future<Result<DeckFileSnapshot>> _loadInitialDeck() {
    return _repository.loadInitialDeck(starterMarkdown: kStarterDeckMarkdown);
  }

  void _retry() {
    setState(() {
      _initialDeck = _loadInitialDeck();
    });
  }

  Future<void> _releaseUnclaimedInitialDeck() async {
    try {
      final result = await _initialDeck;
      if (result case Ok(:final value)) {
        await _repository.releaseDeck(value.reference);
      }
    } catch (_) {
      // Bootstrap errors do not retain a usable bookmark.
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    final session = _fileSession;
    if (session != null) {
      session.dispose();
    } else {
      // A successful load retains a bookmark. If the widget goes away before
      // the route scope mounts, release that unclaimed reference once ready.
      unawaited(_releaseUnclaimedInitialDeck());
    }
    _documentStore?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<DeckFileSnapshot>>(
      future: _initialDeck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _BootstrapMessage(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: $accent.resolve(context),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildFailure(snapshot.error!);
        }

        final result = snapshot.requireData;
        switch (result) {
          case Failure(:final error):
            return _buildFailure(error);
          case Ok(:final value):
            return _buildEditor(value);
        }
      },
    );
  }
}

/// Full-screen centered slot used for the loading spinner and error message.
class _BootstrapMessage extends StatelessWidget {
  const _BootstrapMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: Center(child: child),
    );
  }
}
