import 'dart:convert';
import 'dart:io';

import 'package:superdeck_core/superdeck_core.dart';

String buildMissingBuildOutputMessage(DeckWorkspace workspace) {
  return 'No SuperDeck build output found. Checked '
      '${workspace.deckJson.absolute.path} and '
      '${workspace.buildStatusJson.absolute.path} from cwd '
      '${Directory.current.path}. A directly-launched desktop .app can run '
      'from a different cwd and will not find project-relative .superdeck '
      'files.\n'
      'Fixes:\n'
      '1. Run `dart run superdeck_cli:main build --watch` from the project '
      'directory, then run `flutter run`.\n'
      '2. For a standalone app, build in release with `.superdeck/` bundled '
      'as assets and load with `BundledDeckLoader`.';
}

SlidesLoadedEvent decodeSlidesEvent(String content, String sourceLabel) {
  final decoded = jsonDecode(content);
  if (decoded is! List) {
    throw Exception(
      'Expected JSON array in $sourceLabel, got ${decoded.runtimeType}',
    );
  }
  return SlidesLoadedEvent(parseSlidesContract(decoded));
}

SlidesErrorEvent wrapReferenceError(
  Object error, {
  String message = 'SuperDeck reference error',
}) {
  return SlidesErrorEvent(
    message,
    error: error is Exception ? error : Exception(error.toString()),
  );
}
