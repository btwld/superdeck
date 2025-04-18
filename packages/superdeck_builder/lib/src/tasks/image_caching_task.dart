// This task is currently disabled but kept for reference
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:http/http.dart' as http;
// import 'package:superdeck/superdeck.dart';
// import 'package:logging/logging.dart';

// import '../generator_pipeline.dart';

// /// A task responsible for caching images referenced in markdown slides.
// class ImageCachingTask extends Task {
//   /// A set to track assets currently being processed to prevent duplicate downloads.
//   static final Set<String> _executingAssets = {};

//   /// HTTP client used for downloading images.
//   static final http.Client _httpClient = http.Client();

//   /// Constructs an [ImageCachingTask] with the name 'image_caching'.
//   ImageCachingTask() : super('remote_asset_caching');

//   // Function to download and save a single asset.
//   Future<Uint8List?> _fetchData(TaskContext context, String url) async {
//     try {
//       logger.info('Downloading asset: $url');
//       final response = await _httpClient.get(Uri.parse(url));

//       // Verify successful response.
//       if (response.statusCode != 200) {
//         logger.warning(
//           'Failed to download $url: Status ${response.statusCode}',
//         );

//         return null;
//       }

//       final contentType = response.headers['content-type'] ?? '';
//       // Validate content type.
//       if (!contentType.startsWith('image/')) {
//         logger.warning('Invalid content type for $url: $contentType');

//         return null;
//       }

//       // Define supported image formats.

//       final extension = contentType.split('/').last.toLowerCase();

//       final assetExtension = AssetExtension.tryParse(extension);

//       if (assetExtension == null) {
//         logger.warning('Unsupported image format for $url: $extension');

//         return null;
//       }

//       final asset = GeneratedAsset.image(url, assetExtension);

//       final assetFile = await context.dataStore.getAssetFile(asset);

//       if (await assetFile.exists()) {
//         return null;
//       }

//       await assetFile.writeAsBytes(response.bodyBytes);

//       return response.bodyBytes;
//     } catch (e, stackTrace) {
//       logger.severe('Error downloading asset $url: $e', e, stackTrace);
//     }

//     return null;
//   }

//   @override
//   Future<void> run(TaskContext context) async {
//     // Implementation to be added later
//     return;
//   }
// }
