import 'package:go_router_paths/go_router_paths.dart';

class SDPaths {
  static Path get root => Path('/');
  static ExportPath get export => ExportPath();
  // static Param<Param> get slides => Param('slides', 'slideId');
  static SlidesPath get slides => SlidesPath();

  static ChatPath get chat => ChatPath();
}

class ExportPath extends Path<ExportPath> {
  ExportPath() : super('export');
}

class SlidesPath extends Path<SlidesPath> {
  SlidesPath() : super('slides');
  SlidePath get slide => SlidePath(this);
}

class SlidePath extends Param<SlidePath> {
  SlidePath(SlidesPath slidesPath) : super.only('slideId', parent: slidesPath);
}

class ChatPath extends Path<ChatPath> {
  ChatPath() : super('chat');
}
