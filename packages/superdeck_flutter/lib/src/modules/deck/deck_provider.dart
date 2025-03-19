import 'package:flutter/material.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_flutter/src/components/atoms/async_snapshot_widget.dart';
import 'package:superdeck_flutter/src/modules/common/helpers/root_bundle_data_store.dart';

import '../common/helpers/constants.dart';
import '../common/helpers/provider.dart';
import '../slide_capture/thumbnail_controller.dart';
import 'deck_controller.dart';
import 'deck_options.dart';

class DeckControllerBuilder extends StatelessWidget {
  final DeckOptions options;

  const DeckControllerBuilder({
    super.key,
    required this.builder,
    required this.options,
  });

  final Widget Function(DeckController controller) builder;

  @override
  Widget build(BuildContext context) {
    final configuration = DeckConfiguration();
    final dataStore = kCanRunProcess
        ? FileSystemPresentationRepository(configuration)
        : AssetBundleDataStore(configuration);
    return AsyncStreamWidget(
      stream: dataStore.loadDeckReferenceStream(),
      builder: (snapshot) {
        return _DeckControllerProvider(
          options: options,
          reference: snapshot,
          builder: builder,
          dataStore: dataStore,
        );
      },
    );
  }
}

class _DeckControllerProvider extends StatefulWidget {
  const _DeckControllerProvider({
    required this.options,
    required this.reference,
    required this.builder,
    required this.dataStore,
  });

  final DeckOptions options;
  final DeckReference reference;
  final Widget Function(DeckController controller) builder;
  final PresentationRepository dataStore;
  @override
  State<_DeckControllerProvider> createState() =>
      _DeckControllerProviderState();
}

class _DeckControllerProviderState extends State<_DeckControllerProvider> {
  late final DeckController _deckController;
  late final ThumbnailController _thumbnailController;

  @override
  void initState() {
    super.initState();
    _deckController = DeckController.build(
      slides: widget.reference.slides,
      options: widget.options,
      dataStore: widget.dataStore,
    );
    _thumbnailController = ThumbnailController();
  }

  @override
  void didUpdateWidget(_DeckControllerProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final referenceChanged = widget.reference != oldWidget.reference;
    final optionsChanged = widget.options != oldWidget.options;

    if (referenceChanged || optionsChanged) {
      _deckController.update(
        slides: widget.reference.slides,
        options: widget.options,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _deckController.dispose();
    _thumbnailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedNotifierData(
      data: _deckController,
      child: InheritedNotifierData(
        data: _thumbnailController,
        child: widget.builder(_deckController),
      ),
    );
  }
}
