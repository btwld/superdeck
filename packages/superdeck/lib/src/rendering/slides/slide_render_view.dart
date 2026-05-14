import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../../deck/slide_configuration.dart';
import '../../ui/tokens/colors.dart';
import '../../ui/widgets/provider.dart';
import 'slide_view.dart';

/// Public slide renderer for packages that need to render a configured slide.
class SlideRenderView extends StatelessWidget {
  const SlideRenderView(this.configuration, {super.key});

  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    final oldMixScope = MixScope.maybeOf(context);

    return MixScope(
      colors: SDColors.colorMap,
      tokens: {...oldMixScope?.tokens ?? {}},
      child: InheritedData(
        data: configuration,
        child: SlideView(configuration),
      ),
    );
  }
}
