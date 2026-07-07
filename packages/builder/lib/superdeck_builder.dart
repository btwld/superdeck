/// Code generators and build pipeline for SuperDeck presentations.
library;

export 'package:superdeck_core/superdeck_core.dart'
    show DeckFormatException, DeckPlugin;

export 'src/build/build_event.dart';
export 'src/build/deck_build_plugin.dart';
export 'src/build/deck_builder.dart';

export 'src/parsers/comment_parser.dart';
export 'src/parsers/markdown_parser.dart';
export 'src/parsers/section_parser.dart';
export 'src/parsers/slide_serializer.dart';
