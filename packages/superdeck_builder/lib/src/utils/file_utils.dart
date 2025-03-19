import 'dart:io';

import 'package:path/path.dart' as p;

/// Utility functions for file operations
class FileUtils {
  /// Private constructor to prevent instantiation
  FileUtils._();

  /// Checks if a file exists
  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  /// Checks if a directory exists
  static Future<bool> directoryExists(String path) async {
    return await Directory(path).exists();
  }

  /// Creates a directory if it doesn't exist
  static Future<Directory> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (await directory.exists()) {
      return directory;
    }
    return await directory.create(recursive: true);
  }

  /// Copies a file from source to destination
  /// Creates any needed directories in the process
  static Future<File> copyFile(String source, String destination) async {
    final sourceFile = File(source);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', source);
    }

    final destinationDir = p.dirname(destination);
    await ensureDirectoryExists(destinationDir);

    return await sourceFile.copy(destination);
  }

  /// Gets the file extension from a path
  static String getFileExtension(String path) {
    return p.extension(path).toLowerCase();
  }

  /// Checks if a file is an image based on its extension
  static bool isImageFile(String path) {
    final ext = getFileExtension(path);
    return ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp'].contains(ext);
  }

  /// Checks if a file is a video based on its extension
  static bool isVideoFile(String path) {
    final ext = getFileExtension(path);
    return ['.mp4', '.webm', '.mov', '.avi'].contains(ext);
  }

  /// Checks if a file is an audio file based on its extension
  static bool isAudioFile(String path) {
    final ext = getFileExtension(path);
    return ['.mp3', '.wav', '.ogg', '.aac'].contains(ext);
  }

  /// Read a file as a string
  static Future<String> readFileAsString(String path) async {
    return await File(path).readAsString();
  }

  /// Write a string to a file
  static Future<File> writeStringToFile(String path, String content) async {
    final file = File(path);
    final directory = p.dirname(path);
    await ensureDirectoryExists(directory);
    return await file.writeAsString(content);
  }

  /// Create a temporary file with the given content
  /// Returns the file path
  static Future<String> createTempFile(String content,
      {String? extension}) async {
    final ext = extension ?? '.tmp';
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final filePath = p.join(
      Directory.systemTemp.path,
      'superdeck_${timestamp}$ext',
    );

    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(content);

    return filePath;
  }

  /// Read a file's contents as a string
  static Future<String> readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }

    return await file.readAsString();
  }

  /// Write content to a file
  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    final directory = file.parent;

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await file.writeAsString(content);
  }

  /// Get file extension from path
  static String getFileExtensionFromPath(String path) {
    return p.extension(path);
  }

  /// Join path segments safely
  static String joinPath(List<String> segments) {
    return p.joinAll(segments);
  }

  /// Normalize a file path
  static String normalizePath(String path) {
    return p.normalize(path);
  }

  /// Get absolute path from a potentially relative path
  static String absolutePath(String path, {String? from}) {
    if (p.isAbsolute(path)) {
      return path;
    }

    final base = from ?? Directory.current.path;
    return p.join(base, path);
  }
}
