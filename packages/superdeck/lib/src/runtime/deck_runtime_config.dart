import 'package:meta/meta.dart';
import 'package:superdeck_core/superdeck_core.dart';

class DeckRuntimeConfig {
  final String? projectDir;
  final String? outputDir;
  final String? assetsPath;

  const DeckRuntimeConfig({this.projectDir, this.outputDir, this.assetsPath});

  @internal
  DeckConfiguration toDeckConfiguration({String? slidesPath}) {
    return DeckConfiguration(
      projectDir: projectDir,
      outputDir: outputDir,
      assetsPath: assetsPath,
      slidesPath: slidesPath,
    );
  }
}
