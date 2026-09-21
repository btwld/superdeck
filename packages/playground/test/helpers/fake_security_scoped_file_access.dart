import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:playground/core/data/data_sources/security_scoped_file_access.dart';
import 'package:playground/core/data/data_sources/deck_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Points the repository's settings and default deck folder at a temp root.
class FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

/// Stands in for the macOS picker and bookmark APIs, which need a real user
/// and a real sandbox. Everything below it is ordinary file I/O.
class FakeSecurityScopedFileAccess extends SecurityScopedFileAccess {
  DeckFileReference? picked;
  SecurityScopedDirectoryReference? pickedDirectory;
  final Map<DeckFileReference, DeckFileReference> restored = {};
  final Map<SecurityScopedDirectoryReference, SecurityScopedDirectoryReference>
  restoredDirectories = {};
  final List<DeckFileReference> started = [];
  final List<DeckFileReference> stopped = [];
  final List<SecurityScopedDirectoryReference> startedDirectories = [];
  final List<SecurityScopedDirectoryReference> stoppedDirectories = [];
  Object? startError;
  Object? stopError;

  @override
  Future<DeckFileReference?> pickDeckFile() async => picked;

  @override
  Future<SecurityScopedDirectoryReference?> pickDecksDirectory() async {
    return pickedDirectory;
  }

  @override
  Future<DeckFileReference> startAccessing(DeckFileReference reference) async {
    started.add(reference);
    final error = startError;
    if (error != null) throw error;
    return restored[reference] ?? reference;
  }

  @override
  Future<void> stopAccessing(DeckFileReference reference) async {
    stopped.add(reference);
    final error = stopError;
    if (error != null) throw error;
  }

  @override
  Future<SecurityScopedDirectoryReference> startAccessingDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    startedDirectories.add(reference);
    final error = startError;
    if (error != null) throw error;
    return restoredDirectories[reference] ?? reference;
  }

  @override
  Future<void> stopAccessingDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    stoppedDirectories.add(reference);
    final error = stopError;
    if (error != null) throw error;
  }
}
