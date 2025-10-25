import 'package:flutter/material.dart';
import 'package:superdeck/superdeck.dart';

import 'src/parts/background.dart';
import 'src/parts/footer.dart';
import 'src/parts/header.dart';
import 'src/style.dart';
import 'src/widgets/demo_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable semantics for testing
  WidgetsBinding.instance.ensureSemantics();

  await SuperDeckApp.initialize();
  runApp(
    Builder(
      builder: (context) {
        return MaterialApp(
          title: 'Superdeck',
          debugShowCheckedModeBanner: false,
          showSemanticsDebugger: false,
          home: SuperDeckApp(
            options: DeckOptions(
              baseStyle: borderedStyle(),
              widgets: {
                ...demoWidgets,
                'twitter': (args) {
                  return TwitterWidget(
                    username: args.getString('username'),
                    tweetId: args.getString('tweetId'),
                  );
                },
              },
              // debug: true,
              styles: {
                'announcement': announcementStyle(),
                'quote': quoteStyle(),
                // 'bordered': borderedStyle(),
              },
              parts: const SlideParts(
                header: HeaderPart(),
                footer: FooterPart(),
                background: BackgroundPart(),
              ),
            ),
          ),
        );
      },
    ),
  );
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
