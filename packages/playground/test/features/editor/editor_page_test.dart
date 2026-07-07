import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/app/router.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';
import 'package:playground/features/editor/presentation/widgets/customization_sidebar.dart';
import 'package:playground/features/editor/presentation/widgets/preview_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app() {
    return MaterialApp.router(
      routerConfig: createRouter(),
      builder: (context, child) => _Theme(child: AppProviders(child: child!)),
    );
  }

  testWidgets('editor route builds with its sidebars', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byType(EditorPage), findsOneWidget);
    expect(find.byType(PreviewSidebar), findsOneWidget);
    expect(find.byType(CustomizationSidebar), findsOneWidget);
    // Customization sidebar label renders.
    expect(find.text('Background'), findsOneWidget);

    // Unmount so the editor's controllers/coordinator dispose and cancel their
    // timers, then drain any pending one-shot timers (thumbnail scheduling,
    // deck transition) before the test's timer invariant runs.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}

class _Theme extends StatelessWidget {
  const _Theme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroTheme(
      data: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? .dark()
          : .light(),
      child: child,
    );
  }
}
