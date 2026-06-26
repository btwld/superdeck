import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../deck/slide_configuration.dart';
import '../../ui/tokens/colors.dart';
import '../../ui/widgets/provider.dart';
import 'slide_view.dart';

/// Public slide renderer for packages that need to render a configured slide.
class SlideRenderView extends StatelessWidget {
  const SlideRenderView(this.configuration, {super.key, this.assetCacheStore});

  final SlideConfiguration configuration;

  /// Optional asset cache used to resolve in-slide images referenced by a bare
  /// key (e.g. AI-generated images held in memory). When omitted, an ambient
  /// [AssetCacheStore] from the surrounding tree is used if present.
  final AssetCacheStore? assetCacheStore;

  @override
  Widget build(BuildContext context) {
    final store =
        assetCacheStore ?? InheritedData.maybeOf<AssetCacheStore>(context);

    Widget child = InheritedData(
      data: configuration,
      child: SlideView(configuration),
    );
    if (store != null) {
      child = InheritedData<AssetCacheStore>(data: store, child: child);
    }

    return MixScope.inherit(colors: SDColors.colorMap, child: child);
  }
}
