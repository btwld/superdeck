import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../utils/extensions.dart';
import '../utils/logger.dart';
import '../utils/templates.dart';
import '../utils/update_pubspec.dart';
import 'base_command.dart';

/// Command to set up SuperDeck in a Flutter project
///
/// This command ensures that:
/// 1. The pubspec.yaml has the necessary assets configuration
/// 2. If macOS is present, the entitlements files are properly configured
/// 3. A basic slides.md file is created if none exists
/// 4. Custom index.html is set up with a loading indicator for web
class SetupCommand extends SuperdeckCommand {
  /// Creates a new [SetupCommand] instance
  SetupCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force setup without confirmation prompts',
      negatable: false,
    );
    argParser.addFlag(
      'setup-web',
      help: 'Set up custom index.html for web with loading indicator',
      defaultsTo: true,
    );
  }

  /// Ask for user confirmation before performing an action
  bool _confirmAction(String message, {bool defaultValue = false}) {
    final response = logger.confirm(message, defaultValue: defaultValue);

    return response;
  }

  /// Create a basic slides.md file with a simple example
  Future<void> _createEmptySlides(File slidesFile) async {
    final progress = logger.progress('Creating slides.md file...');

    try {
      const content = '''---

@column

# Welcome to SuperDeck

Your awesome slides start here!

@column

- Create beautiful slides using markdown
- Arrange content using the block-based system
- Customize with images, widgets, and more

---

@column

## Example of a multi-column slide

- This content appears in the left column
- Add more items here

@column {
  align: center_right
}

This content appears in the right column.

![Sample Image](https://picsum.photos/800/600)

---

@column {
  align: center
}

# Thank You!

Built with SuperDeck
''';

      // Create the parent directory if it doesn't exist
      final directory = slidesFile.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await slidesFile.writeAsString(content);
      progress.complete('Created slides.md file');
    } catch (e) {
      progress.fail('Failed to create slides.md file');
      rethrow;
    }
  }

  /// Set up a custom index.html with loading indicator for web
  Future<void> _setupCustomIndexHtml(Directory projectDir) async {
    final progress = logger.progress('Setting up custom index.html for web...');

    try {
      // Look for web directory
      final webDir = Directory(path.join(projectDir.path, 'web'));

      if (!await webDir.exists()) {
        progress.fail('Web directory not found');
        logger.warn('Web directory not found at ${webDir.path}');

        return;
      }

      final indexHtmlPath = path.join(webDir.path, 'index.html');
      final indexHtmlFile = File(indexHtmlPath);

      if (await indexHtmlFile.exists()) {
        // Create a backup of the original index.html
        final backupPath = path.join(webDir.path, 'index.html.bak');
        await indexHtmlFile.copy(backupPath);
        logger.detail('Created backup of original index.html at $backupPath');

        // Replace with our custom template
        await indexHtmlFile.writeAsString(customIndexHtml);
        progress.complete('Custom index.html set up with loading indicator');
      } else {
        // Create new index.html if it doesn't exist
        await indexHtmlFile.writeAsString(customIndexHtml);
        progress.complete('Created custom index.html with loading indicator');
      }
    } catch (e) {
      progress.fail('Failed to set up custom index.html');
      logger.err('Error setting up custom index.html: $e');
    }
  }


  /// Configure macOS entitlements
  Future<void> _setupMacOSEntitlements(Directory macosDir) async {
    final progress = logger.progress('Configuring macOS entitlements...');

    try {
      // Release.entitlements
      final releaseEntitlements =
          File(path.join(macosDir.path, 'Runner', 'Release.entitlements'));
      if (await releaseEntitlements.exists()) {
        await _updateEntitlements(
          releaseEntitlements,
          appSandbox: false,
          networkClient: true,
        );
      } else {
        progress.update('Release.entitlements not found');
        logger.warn(
          'Release.entitlements not found at ${releaseEntitlements.path}',
        );
      }

      // DebugProfile.entitlements
      final debugEntitlements =
          File(path.join(macosDir.path, 'Runner', 'DebugProfile.entitlements'));
      if (await debugEntitlements.exists()) {
        await _updateEntitlements(
          debugEntitlements,
          appSandbox: false,
          networkClient: true,
          networkServer: true,
          allowJit: true,
        );
      } else {
        progress.update('DebugProfile.entitlements not found');
        logger.warn(
          'DebugProfile.entitlements not found at ${debugEntitlements.path}',
        );
      }

      progress.complete('macOS entitlements configured');
    } catch (e) {
      progress.fail('Failed to configure macOS entitlements');
      rethrow;
    }
  }

  /// Update entitlements file
  Future<void> _updateEntitlements(
    File file, {
    required bool appSandbox,
    bool networkClient = false,
    bool networkServer = false,
    bool allowJit = false,
  }) async {
    final content = await file.readAsString();

    // Create new entitlements content
    final updatedContent = _generateEntitlementsXml(
      appSandbox: appSandbox,
      networkClient: networkClient,
      networkServer: networkServer,
      allowJit: allowJit,
    );

    // Only update if content is different
    if (content.trim() != updatedContent.trim()) {
      await file.writeAsString(updatedContent);
      logger.success('Updated ${file.path}');
    } else {
      logger.info('${file.path} already configured correctly');
    }
  }

  /// Generate XML content for entitlements file
  String _generateEntitlementsXml({
    required bool appSandbox,
    bool networkClient = false,
    bool networkServer = false,
    bool allowJit = false,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
    );
    buffer.writeln('<plist version="1.0">');
    buffer.writeln('<dict>');

    buffer.writeln('   <key>com.apple.security.app-sandbox</key>');
    buffer.writeln('   <${appSandbox ? 'true' : 'false'}/>');

    if (networkClient) {
      buffer.writeln('   <key>com.apple.security.network.client</key>');
      buffer.writeln('   <true/>');
    }

    if (networkServer) {
      buffer.writeln('   <key>com.apple.security.network.server</key>');
      buffer.writeln('   <true/>');
    }

    if (allowJit) {
      buffer.writeln('   <key>com.apple.security.cs.allow-jit</key>');
      buffer.writeln('   <true/>');
    }

    buffer.writeln('</dict>');
    buffer.writeln('</plist>');

    return buffer.toString();
  }


  @override
  Future<int> run() async {
    try {
      final deckConfig = await loadConfiguration();

      int successCount = 0;
      int warningCount = 0;
      int errorCount = 0;

      // Check if slides.md exists, if not create it
      final slidesFile = deckConfig.slidesFile;
      if (!await slidesFile.exists()) {
        final createSlides = boolArg('force') ||
            _confirmAction('Create slides.md file?', defaultValue: true);

        if (createSlides) {
          try {
            await _createEmptySlides(slidesFile);
            successCount++;
          } catch (e) {
            logger.err('Failed to create slides.md file: $e');
            errorCount++;
          }
        } else {
          logger.info('Skipped creating slides.md file');
          warningCount++;
        }
      } else {
        logger.info('slides.md file already exists');
      }

      // Set up web support with custom index.html if requested
      final setupWeb = argResults?['setup-web'] as bool? ?? true;
      if (setupWeb) {
        try {
          final projectDir = Directory.current;
          await _setupCustomIndexHtml(projectDir);
          successCount++;
        } catch (e) {
          logger.err('Failed to set up web support: $e');
          errorCount++;
        }
      }

      // Setup pubspec.yaml for SuperDeck
      try {
        final pubspecFile = deckConfig.pubspecFile;
        if (await pubspecFile.exists()) {
          final pubspecContents = await pubspecFile.readAsString();
          final updatedPubspec =
              updatePubspecAssets(deckConfig, pubspecContents);

          if (updatedPubspec != pubspecContents) {
            final updatePubspec = boolArg('force') ||
                _confirmAction(
                  'Update pubspec.yaml with required assets?',
                  defaultValue: true,
                );

            if (updatePubspec) {
              await pubspecFile.writeAsString(updatedPubspec);
              logger.success('Updated pubspec.yaml with required assets');
              successCount++;
            } else {
              logger.info('Skipped updating pubspec.yaml');
              warningCount++;
            }
          } else {
            logger.info('pubspec.yaml already has required assets');
          }
        } else {
          logger.warn('pubspec.yaml not found');
          warningCount++;
        }
      } catch (e) {
        logger.err('Error updating pubspec.yaml: $e');
        errorCount++;
      }

      // Check for macOS support and configure entitlements if needed
      final macosDir = Directory('macos');
      if (await macosDir.exists()) {
        try {
          await _setupMacOSEntitlements(macosDir);
          successCount++;
        } catch (e) {
          logger.err('Failed to configure macOS entitlements: $e');
          errorCount++;
        }
      } else {
        logger.info('macOS directory not found, skipping entitlements setup');
      }

      // Print summary
      logger.info('');
      logger.info('Setup completed:');
      logger.info(
        '  ${successCount.toString().padLeft(2)} successful operations',
      );
      logger.info('  ${warningCount.toString().padLeft(2)} warnings');
      logger.info('  ${errorCount.toString().padLeft(2)} errors');

      if (errorCount > 0) {
        logger.info('');
        logger.warn(
          'Some errors occurred during setup. Check the logs above for details.',
        );

        return ExitCode.software.code;
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      logger.err('Setup failed: $e');
      logger.detail('$stackTrace');

      return ExitCode.software.code;
    }
  }

  @override
  String get description => 'Set up SuperDeck in your Flutter project';

  @override
  String get name => 'setup';
}
