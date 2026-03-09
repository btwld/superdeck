import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_genui/src/ai/prompts/prompt_registry.dart';
import 'package:superdeck_genui/src/bootstrap/genui_bootstrap.dart';
import 'package:superdeck_genui/src/path_service.dart';
import 'package:superdeck_genui/src/routes.dart';
import 'package:superdeck_genui/src/utils/deck_style_service.dart';
import 'package:superdeck_genui/src/utils/style_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathService.instance.setBaseDirForTest('.superdeck');
    PromptRegistry.instance.loadForTest(prompts: {'test': 'prompt'});
    await GenUiBootstrap.ensureInitialized(loadDotEnv: false);
  });

  setUp(() {
    DeckStyleService.clearCache();
  });

  tearDownAll(() {
    DeckStyleService.clearCache();
    PromptRegistry.instance.reset();
    PathService.instance.resetForTest();
    GenUiBootstrap.resetForTest();
  });

  testWidgets('default presentation route uses local config on test runtime', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: GenUiRoutes.presentation,
      routes: genUiRoutes(),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    final provider = tester.widget<SuperDeckProvider>(
      find.byType(SuperDeckProvider),
    );

    expect(provider.config, isA<LocalDeckConfig>());
    expect((provider.config as LocalDeckConfig).watch, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('custom presentationBuilder overrides the whole route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: GenUiRoutes.presentation,
      routes: genUiRoutes(
        presentationBuilder: (context, state) => const Text('custom route'),
      ),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('custom route'), findsOneWidget);
    expect(find.byType(SuperDeckProvider), findsNothing);
  });

  testWidgets('presentation route applies style extra before rendering', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: GenUiRoutes.chat,
      routes: genUiRoutes(
        chatBuilder: (context, state) => const SizedBox.shrink(),
        presentationBuilder: (context, state) {
          final theme = buildDeckThemeFromStyle(
            DeckStyleService.readStyleFromCache(),
          );
          return Text(theme.baseStyle == null ? 'no-theme' : 'has-theme');
        },
      ),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    router.go(
      GenUiRoutes.presentation,
      extra: {
        'style': {
          'name': 'Styled',
          'colors': {
            'background': '#FFFFFF',
            'heading': '#112233',
            'body': '#445566',
          },
          'fonts': {'headline': 'montserrat', 'body': 'openSans'},
        },
      },
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('has-theme'), findsOneWidget);
    expect(DeckStyleService.readStyleFromCache()?.name, 'Styled');
  });
}
