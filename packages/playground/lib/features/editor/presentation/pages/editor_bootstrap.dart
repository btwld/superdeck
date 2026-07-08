import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/data/data_sources/app_settings_store.dart';
import '../../../../core/data/data_sources/deck_file_store.dart';
import '../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../ai/quick_agent/domain/commands/generate_deck_command.dart';
import '../../domain/stores/deck_file_controller.dart';
import '../../domain/stores/editor_store.dart';
import '../../utils/text_editor_controller.dart';
import 'editor_page.dart';

/// Resolves the file-backed deck before the editor mounts.
///
/// The editor must be seeded with the last-opened file's content (loaded
/// asynchronously), so this widget owns the [DeckFileController], awaits its
/// [DeckFileController.initialize], and only then builds the editor's scoped
/// providers — wiring the controller's auto-save sink and reload port to the
/// freshly-built [TextEditorController].
class EditorBootstrap extends StatefulWidget {
  const EditorBootstrap({super.key});

  @override
  State<EditorBootstrap> createState() => _EditorBootstrapState();
}

class _EditorBootstrapState extends State<EditorBootstrap> {
  late final DeckFileController _fileController;
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _fileController = DeckFileController(
      store: context.read<DeckFileStore>(),
      settings: context.read<AppSettingsStore>(),
    );
    _ready = _fileController.initialize();
  }

  @override
  void dispose() {
    _fileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
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
          return _BootstrapMessage(
            child: Text(
              'Could not open the decks folder.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: $muted.resolve(context)),
            ),
          );
        }
        return _buildEditor(context);
      },
    );
  }

  Widget _buildEditor(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeckFileController>.value(
          value: _fileController,
        ),
        ChangeNotifierProvider(create: (_) => EditorStore()),
        Provider<TextEditorController>(
          lazy: false,
          create: (ctx) {
            final controller = TextEditorController(
              editorStore: ctx.read<EditorStore>(),
              deckLoader: ctx.read<MemoryDeckLoader>(),
              initialText: _fileController.content,
              onMarkdownChanged: _fileController.handleEditorChange,
            );
            _fileController.attachEditor(controller);
            return controller;
          },
          dispose: (_, controller) => controller.dispose(),
        ),
        ListenableProvider<GenerateDeckCommand>(
          create: (ctx) =>
              GenerateDeckCommand(editor: ctx.read<TextEditorController>()),
          dispose: (_, command) => command.dispose(),
        ),
      ],
      child: const EditorPage(),
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
