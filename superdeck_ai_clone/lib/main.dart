import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_ai/core/ai/prompts/examples_loader.dart';
import 'package:superdeck_ai/core/ai/prompts/prompt_registry.dart';
import 'package:superdeck_ai/core/viewmodel_scope.dart';
import 'package:superdeck_ai/core/debug_logger.dart';
import 'package:superdeck_ai/core/router.dart';
import 'package:superdeck_ai/core/path_service.dart';
import 'package:superdeck_ai/core/utils/deck_style_service.dart';
import 'package:superdeck_ai/presentation/presentation_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web is intentionally unsupported for this release.
  if (kIsWeb) {
    runApp(const WebUnsupportedApp());
    return;
  }

  // Enable accessibility/semantics for screen readers and browser automation
  SemanticsBinding.instance.ensureSemantics();

  // Initialize platform-aware path resolution (must be first - others depend on it)
  await PathService.instance.initialize();

  // Initialize debug logger early so we can log startup events
  try {
    await DebugLogger.instance.init();
  } catch (e) {
    debugPrint('[MAIN] Debug logger initialization failed: $e');
  }
  debugLog.section('App Started');

  // Try to load .env file (optional - may use --dart-define instead)
  try {
    await dotenv.load();
    debugLog.log('ENV', '.env file loaded');
  } catch (e) {
    debugLog.log('ENV', '.env not found, using --dart-define: $e');
  }
  try {
    await PromptRegistry.instance.load();
    debugLog.log('PROMPT', 'Prompt assets loaded');
    await ExamplesLoader.instance.load();
    debugLog.log(
      'EXAMPLES',
      'Example assets loaded (${ExamplesLoader.instance.examples.length} examples)',
    );
  } catch (e, stack) {
    debugLog.error('PROMPT', e, stack);
  }

  SignalsObserver.instance = null;
  configureGenUiLogging(
    level: Level.ALL,
    logCallback: (level, message) => debugLog.log('GenUI:$level', message),
  );

  try {
    await SuperDeckApp.initialize();
  } catch (e, stack) {
    debugLog.error('SUPERDECK', e, stack);
  }

  // Preload style cache asynchronously (non-blocking for router)
  await DeckStyleService.preloadStyle();

  runApp(const MyApp());
}

class WebUnsupportedApp extends StatelessWidget {
  const WebUnsupportedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline, size: 48),
                SizedBox(height: 12),
                Text(
                  'Web is not supported in this release.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<PresentationViewModel>(
      create: () => PresentationViewModel(),
      child: MaterialApp.router(
        builder: (context, child) {
          return createRemixScope(child: child!, accent: .iris);
        },
        routerConfig: router,
      ),
    );
  }
}
