import '../../../core/data/data_sources/deck_file.dart';

/// Directory suffix that pairs a saved deck with its artwork.
const kDeckAssetsSuffix = '.assets';

/// Filename suffix of the metadata written beside a saved deck.
const kDeckManifestSuffix = '.deck.json';

/// The theme a deck was generated with, in the catalog's own terms.
///
/// Only the selection is stored. Resolved colours and fonts are derived from
/// the catalog at open time, so a deck saved against catalog version 1 can be
/// recognised — and refused — by a catalog that moved on.
final class SavedDeckTheme {
  final String id;
  final int version;
  final String density;

  const SavedDeckTheme({
    required this.id,
    required this.version,
    required this.density,
  });

  factory SavedDeckTheme.fromJson(Map<String, Object?> json) => SavedDeckTheme(
    id: json['id']! as String,
    version: (json['version']! as num).toInt(),
    density: json['density']! as String,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'density': density,
  };

  @override
  bool operator ==(Object other) =>
      other is SavedDeckTheme &&
      other.id == id &&
      other.version == version &&
      other.density == density;

  @override
  String toString() => 'SavedDeckTheme($id v$version, $density)';

  @override
  int get hashCode => Object.hash(id, version, density);
}

/// What a saved deck carries beside its Markdown.
///
/// The manifest is the deck's canonical description: the format version that
/// wrote it, the display name, the artwork the Markdown refers to, and the
/// theme selection. A deck whose manifest cannot be read still opens; it just
/// opens without a theme.
final class SavedDeckManifest {
  /// Current manifest format. Bump when a field changes meaning.
  static const currentFormatVersion = 1;

  final int formatVersion;
  final String name;
  final DateTime savedAt;
  final String markdownFileName;
  final String assetsDirectoryName;
  final List<String> assetKeys;
  final SavedDeckTheme? theme;

  const SavedDeckManifest({
    required this.formatVersion,
    required this.name,
    required this.savedAt,
    required this.markdownFileName,
    required this.assetsDirectoryName,
    required this.assetKeys,
    this.theme,
  });

  factory SavedDeckManifest.fromJson(Map<String, Object?> json) {
    final formatVersion = (json['formatVersion'] as num?)?.toInt();
    if (formatVersion == null) {
      throw const FormatException('Deck manifest has no formatVersion.');
    }
    if (formatVersion > currentFormatVersion) {
      throw FormatException(
        'Deck manifest format $formatVersion is newer than this app '
        'understands ($currentFormatVersion).',
      );
    }
    final savedAt = switch (json['savedAt']) {
      final String value => DateTime.tryParse(value),
      _ => null,
    };
    if (savedAt == null) {
      throw const FormatException('Deck manifest has no savedAt timestamp.');
    }

    return SavedDeckManifest(
      formatVersion: formatVersion,
      name: json['name']! as String,
      savedAt: savedAt,
      markdownFileName: json['markdownFileName']! as String,
      assetsDirectoryName: json['assetsDirectoryName']! as String,
      assetKeys: [
        for (final key in (json['assetKeys'] as List? ?? const []))
          key as String,
      ],
      theme: switch (json['theme']) {
        final Map<String, Object?> theme => SavedDeckTheme.fromJson(theme),
        _ => null,
      },
    );
  }

  Map<String, Object?> toJson() => {
    'formatVersion': formatVersion,
    'name': name,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'markdownFileName': markdownFileName,
    'assetsDirectoryName': assetsDirectoryName,
    'assetKeys': assetKeys,
    'theme': ?theme?.toJson(),
  };
}

/// A deck on disk, named well enough to list and reopen it.
final class SavedDeckRef {
  final DeckFileReference reference;
  final String name;
  final DateTime savedAt;

  const SavedDeckRef({
    required this.reference,
    required this.name,
    required this.savedAt,
  });

  @override
  bool operator ==(Object other) =>
      other is SavedDeckRef &&
      other.reference == reference &&
      other.name == name &&
      other.savedAt == savedAt;

  @override
  String toString() => 'SavedDeckRef($name, ${reference.path})';

  @override
  int get hashCode => Object.hash(reference, name, savedAt);
}

/// A saved deck read back for presentation.
final class SavedDeck {
  final SavedDeckRef ref;
  final String markdown;
  final SavedDeckManifest? manifest;

  const SavedDeck({
    required this.ref,
    required this.markdown,
    this.manifest,
  });

  /// The theme the deck was saved with, when its manifest carried one.
  SavedDeckTheme? get theme => manifest?.theme;
}
