import 'dart:io';

import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_example/src/layout_showcase/showcase_workspace.dart';

Future<void> main() async {
  final store = DeckBuildStore(workspace: layoutShowcaseWorkspace);
  final builder = DeckBuilder(workspace: layoutShowcaseWorkspace, store: store);

  try {
    final slides = await builder.build();
    stdout.writeln('Built ${slides.length} layout showcase slides.');
  } finally {
    await builder.dispose();
  }
}
