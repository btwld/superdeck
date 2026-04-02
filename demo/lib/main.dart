import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'src/parts/background.dart';
import 'src/parts/footer.dart';
import 'src/parts/header.dart';
import 'src/style.dart';
import 'src/templates.dart';
import 'src/widgets/demo_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable signals logging to reduce console noise
  SignalsObserver.instance = null;

  // Enable semantics for testing
  WidgetsBinding.instance.ensureSemantics();

  await SuperDeckApp.initialize();
  runApp(
    SuperDeckApp(
      options: DeckOptions(
        baseStyle: borderedStyle(),
        widgets: {...demoWidgets, 'twitter': _twitterWidget},
        // debug: true,
        styles: {'announcement': announcementStyle(), 'quote': quoteStyle()},
        templates: {
          'corporate': corporateTemplate(),
          'minimal': minimalTemplate(),
        },
        parts: const SlideParts(
          header: HeaderPart(),
          footer: FooterPart(),
          background: BackgroundPart(),
        ),
      ),
    ),
  );
}

class TwitterWidget extends StatelessWidget {
  final String username;

  const TwitterWidget({super.key, required this.username});

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

Widget _twitterWidget(Map<String, Object?> args) {
  final username = args['username'] as String? ?? '';
  return TwitterWidget(username: username);
}
