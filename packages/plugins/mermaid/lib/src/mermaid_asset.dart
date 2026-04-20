import 'package:superdeck_core/superdeck_core.dart';

/// Builds a [GeneratedAsset] reference for a Mermaid diagram.
///
/// The asset uses the `mermaid` type with a PNG extension, and a name derived
/// from the hash of [syntax] so identical diagrams resolve to the same asset.
GeneratedAsset mermaidAsset(String syntax) {
  return GeneratedAsset(
    name: GeneratedAsset.buildKey(syntax),
    extension: AssetExtension.png,
    type: 'mermaid',
  );
}
