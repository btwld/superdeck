import 'package:flutter/services.dart';
import 'package:superdeck/superdeck.dart';

class AssetBundleDataStore extends LocalPresentationRepository {
  AssetBundleDataStore(super.configuration);

  @override
  Future<String> fileReader(String path) async => rootBundle.loadString(path);
}
