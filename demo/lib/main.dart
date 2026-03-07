import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_genui/superdeck_genui.dart';

import 'src/parts/background.dart';
import 'src/parts/footer.dart';
import 'src/parts/header.dart';
import 'src/style.dart';
import 'src/templates.dart';
import 'src/widgets/demo_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const extensions = [GenUiPlugin()];
  final config = kIsWeb
      ? const DeckConfig.bundle(
          projectDir: '.',
          outputDir: '.superdeck',
          assetsPath: 'assets',
        )
      : const DeckConfig.local(
          slidesPath: 'slides.md',
          watch: true,
          projectDir: '.',
          outputDir: '.superdeck',
          assetsPath: 'assets',
        );

  // Disable signals logging to reduce console noise
  SignalsObserver.instance = null;

  // Enable semantics for testing
  WidgetsBinding.instance.ensureSemantics();

  final runtime = await SuperDeckRuntime.create(
    config: config,
    theme: DeckTheme(
      baseStyle: borderedStyle(),
      widgets: {...demoWidgets, 'twitter': const _TwitterBlockDefinition()},
      styles: {'announcement': announcementStyle(), 'quote': quoteStyle()},
      templates: {
        'corporate': corporateTemplate(),
        'minimal': minimalTemplate(),
      },
      frame: SlideFrame(
        header: HeaderPart(),
        footer: FooterPart(),
        background: BackgroundPart(),
      ),
    ),
    extensions: extensions,
  );

  runApp(SuperDeckApp(runtime: runtime));
}

class TwitterWidget extends StatelessWidget {
  final String username;
  final String tweetId;

  const TwitterWidget({
    super.key,
    required this.username,
    required this.tweetId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Twitter: $username',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _TwitterBlockDefinition extends BlockDefinition<Map<String, Object?>> {
  const _TwitterBlockDefinition();

  @override
  Map<String, Object?> parse(Map<String, Object?> args) {
    // No validation - just pass through
    return args;
  }

  @override
  Widget build(BuildContext context, Map<String, Object?> args) {
    final username = args['username'] as String? ?? '';
    final tweetId = args['tweetId'] as String? ?? '';
    return TwitterWidget(username: username, tweetId: tweetId);
  }
}
