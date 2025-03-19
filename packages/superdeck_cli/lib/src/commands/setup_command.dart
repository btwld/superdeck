import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_core/superdeck_core.dart';

import '../helpers/logger.dart';
import '../helpers/update_pubspec.dart';

/// Command to set up SuperDeck in a Flutter project
///
/// This command ensures that:
/// 1. The pubspec.yaml has the necessary assets configuration
/// 2. If macOS is present, the entitlements files are properly configured
/// 3. A basic slides.md file is created if none exists
class SetupCommand extends Command<int> {
  /// Creates a new [SetupCommand] instance
  SetupCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force setup without confirmation prompts',
      negatable: false,
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

  /// Returns the value of a boolean argument
  bool boolArg(String name) => argResults?[name] as bool? ?? false;

  @override
  Future<int> run() async {
    try {
      final configFile = DeckConfiguration.defaultFile;
      DeckConfiguration deckConfig;

      final progress = logger.progress('Loading configuration...');

      try {
        // Load the configuration file or use defaults if it doesn't exist.
        if (!await configFile.exists()) {
          progress.update(
            'Configuration file not found. Using default configuration.',
          );
          deckConfig = DeckConfiguration();
        } else {
          progress.update('Loading configuration from ${configFile.path}');
          final yamlConfig = await YamlUtils.loadYamlFile(configFile);
          deckConfig = DeckConfiguration.parse(yamlConfig);
        }
        progress.complete('Configuration loaded.');
      } catch (e) {
        progress.fail('Failed to load configuration: $e');
        logger
            .err('Unable to load configuration. Using default configuration.');
        deckConfig = DeckConfiguration();
      }

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
            logger.success('Created slides.md file');
            successCount++;
          } catch (e) {
            logger.err('Failed to create slides.md file: $e');
            errorCount++;
          }
        } else {
          logger.warn('slides.md file not created');
          warningCount++;
        }
      } else {
        logger.info('slides.md file already exists');
      }

      // Update pubspec assets
      final pubspecFile = deckConfig.pubspecFile;
      if (await pubspecFile.exists()) {
        try {
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
              logger.warn('pubspec.yaml not updated');
              warningCount++;
            }
          } else {
            logger.info('pubspec.yaml already has required assets');
          }
        } catch (e) {
          logger.err('Failed to update pubspec.yaml: $e');
          errorCount++;
        }
      } else {
        logger.warn('pubspec.yaml not found');
        warningCount++;
      }

      // Check for macOS folder and update entitlements if needed
      final macosDir = Directory(path.join(Directory.current.path, 'macos'));
      if (await macosDir.exists()) {
        final shouldConfigureMacos = boolArg('force') ||
            _confirmAction(
              'Configure macOS entitlements?',
              defaultValue: true,
            );

        if (shouldConfigureMacos) {
          try {
            await _setupMacOSEntitlements(macosDir);
            logger.success('macOS entitlements configured');
            successCount++;
          } catch (e) {
            logger.err('Failed to configure macOS entitlements: $e');
            errorCount++;
          }
        } else {
          logger.warn('macOS entitlements not configured');
          warningCount++;
        }
      } else {
        logger.info('macOS directory not found. Skipping entitlements setup.');
      }

      logger.info('');
      logger.info('Setup summary:');
      logger.info('$successCount operations completed successfully');
      if (warningCount > 0) {
        logger.info('$warningCount operations skipped or with warnings');
      }
      if (errorCount > 0) {
        logger.info('$errorCount operations failed');
      }

      logger.info('');

      if (errorCount > 0) {
        logger.warn('Setup completed with errors');
      } else if (warningCount > 0) {
        logger.info('Setup completed with warnings');
      } else {
        logger.success('SuperDeck setup completed successfully!');
      }

      logger.info('');
      logger.info('Next steps:');
      logger.info('  1. Edit your slides.md file');
      logger.info('  2. Run `superdeck build` to generate assets');
      logger.info('  3. Run your Flutter app');

      return errorCount > 0 ? ExitCode.software.code : ExitCode.success.code;
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
