import 'package:ack/ack.dart';
import 'package:collection/collection.dart';

class ThumbnailManifest {
  final int schemaVersion;
  final ThumbnailRenderSignature renderSignature;
  final List<ThumbnailManifestSlide> slides;

  ThumbnailManifest({
    required this.schemaVersion,
    required this.renderSignature,
    required List<ThumbnailManifestSlide> slides,
  }) : slides = List.unmodifiable(slides);

  ThumbnailManifest copyWith({
    int? schemaVersion,
    ThumbnailRenderSignature? renderSignature,
    List<ThumbnailManifestSlide>? slides,
  }) {
    return ThumbnailManifest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      renderSignature: renderSignature ?? this.renderSignature,
      slides: slides ?? this.slides,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'render_signature': renderSignature.toMap(),
      'slides': slides.map((slide) => slide.toMap()).toList(),
    };
  }

  static ThumbnailManifest fromMap(Map<String, dynamic> map) {
    return ThumbnailManifest(
      schemaVersion: (map['schema_version'] as num).toInt(),
      renderSignature: ThumbnailRenderSignature.fromMap(
        map['render_signature'] as Map<String, dynamic>,
      ),
      slides: (map['slides'] as List<dynamic>)
          .map(
            (entry) =>
                ThumbnailManifestSlide.fromMap(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static ThumbnailManifest parse(Map<String, dynamic> map) {
    schema.parse(map);
    return fromMap(map);
  }

  static final schema = Ack.object({
    'schema_version': Ack.integer(),
    'render_signature': ThumbnailRenderSignature.schema,
    'slides': Ack.list(ThumbnailManifestSlide.schema),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThumbnailManifest &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          renderSignature == other.renderSignature &&
          const ListEquality().equals(slides, other.slides);

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    renderSignature,
    const ListEquality().hash(slides),
  );
}

class ThumbnailRenderSignature {
  final int viewportWidth;
  final int viewportHeight;
  final double devicePixelRatio;
  final int quality;

  const ThumbnailRenderSignature({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.devicePixelRatio,
    required this.quality,
  });

  ThumbnailRenderSignature copyWith({
    int? viewportWidth,
    int? viewportHeight,
    double? devicePixelRatio,
    int? quality,
  }) {
    return ThumbnailRenderSignature(
      viewportWidth: viewportWidth ?? this.viewportWidth,
      viewportHeight: viewportHeight ?? this.viewportHeight,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      quality: quality ?? this.quality,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'viewport_width': viewportWidth,
      'viewport_height': viewportHeight,
      'device_pixel_ratio': devicePixelRatio,
      'quality': quality,
    };
  }

  static ThumbnailRenderSignature fromMap(Map<String, dynamic> map) {
    return ThumbnailRenderSignature(
      viewportWidth: (map['viewport_width'] as num).toInt(),
      viewportHeight: (map['viewport_height'] as num).toInt(),
      devicePixelRatio: (map['device_pixel_ratio'] as num).toDouble(),
      quality: (map['quality'] as num).toInt(),
    );
  }

  static final schema = Ack.object({
    'viewport_width': Ack.integer(),
    'viewport_height': Ack.integer(),
    'device_pixel_ratio': Ack.anyOf([Ack.double(), Ack.integer()]),
    'quality': Ack.integer(),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThumbnailRenderSignature &&
          runtimeType == other.runtimeType &&
          viewportWidth == other.viewportWidth &&
          viewportHeight == other.viewportHeight &&
          devicePixelRatio == other.devicePixelRatio &&
          quality == other.quality;

  @override
  int get hashCode =>
      Object.hash(viewportWidth, viewportHeight, devicePixelRatio, quality);
}

class ThumbnailManifestSlide {
  final String slideKey;
  final String fileName;

  const ThumbnailManifestSlide({
    required this.slideKey,
    required this.fileName,
  });

  ThumbnailManifestSlide copyWith({String? slideKey, String? fileName}) {
    return ThumbnailManifestSlide(
      slideKey: slideKey ?? this.slideKey,
      fileName: fileName ?? this.fileName,
    );
  }

  Map<String, dynamic> toMap() {
    return {'slide_key': slideKey, 'file_name': fileName};
  }

  static ThumbnailManifestSlide fromMap(Map<String, dynamic> map) {
    return ThumbnailManifestSlide(
      slideKey: map['slide_key'] as String,
      fileName: map['file_name'] as String,
    );
  }

  static final schema = Ack.object({
    'slide_key': Ack.string(),
    'file_name': Ack.string(),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThumbnailManifestSlide &&
          runtimeType == other.runtimeType &&
          slideKey == other.slideKey &&
          fileName == other.fileName;

  @override
  int get hashCode => Object.hash(slideKey, fileName);
}
