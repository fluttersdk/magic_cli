import 'dart:io';

import 'package:fluttersdk_magic_cli/src/console/command.dart';

/// Make Lang Command.
///
/// Scaffolds a new translation JSON file and updates pubspec.yaml.
///
/// ## Usage
///
/// ```bash
/// magic make:lang fr
/// magic make:lang tr
/// ```
class MakeLangCommand extends Command {
  @override
  String get name => 'make:lang';

  @override
  String get description => 'Create a new translation file';

  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a locale code (e.g., make:lang fr)');
      return;
    }

    final locale = arguments.rest.first.toLowerCase();

    // Validate locale format
    if (!RegExp(r'^[a-z]{2}$').hasMatch(locale)) {
      error('Invalid locale format. Use 2-letter code (e.g., en, fr, tr)');
      return;
    }

    final directory = Directory('assets/lang');
    final file = File('${directory.path}/$locale.json');

    // Create directory if needed
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      comment('Created assets/lang/ directory');
    }

    // Check if file exists
    if (file.existsSync()) {
      comment('Translation file already exists: ${file.path}');
      return;
    }

    // Create the translation file
    final content = _generateContent();
    file.writeAsStringSync(content);
    info('Created translation file: ${file.path}');

    // Add asset to pubspec.yaml
    await _addToPubspec(locale);
  }

  /// Add the language asset to pubspec.yaml.
  Future<void> _addToPubspec(String locale) async {
    final pubspecFile = File('pubspec.yaml');

    if (!pubspecFile.existsSync()) {
      comment('pubspec.yaml not found, skipping asset registration');
      return;
    }

    final content = pubspecFile.readAsStringSync();
    final assetLine = '    - assets/lang/$locale.json';

    // Check if already registered
    if (content.contains('assets/lang/$locale.json')) {
      comment('Asset already registered in pubspec.yaml');
      return;
    }

    // Find the assets section and add the new asset
    final lines = content.split('\n');
    final newLines = <String>[];
    var foundAssets = false;
    var addedAsset = false;
    var assetsIndent = '';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      newLines.add(line);

      // Detect assets: section under flutter:
      if (line.trim() == 'assets:') {
        foundAssets = true;
        // Get the indentation of existing assets
        assetsIndent = line.substring(0, line.indexOf('assets:'));
        continue;
      }

      // If we found assets and this line is an asset entry, track last position
      if (foundAssets && !addedAsset) {
        // Check if this line is an asset entry (starts with -)
        if (line.trim().startsWith('- ') && line.contains('assets/')) {
          // Check if next line is not an asset entry (end of assets section)
          if (i + 1 >= lines.length ||
              !lines[i + 1].trim().startsWith('- ') ||
              !lines[i + 1].contains('assets/')) {
            // Add our new asset after this one
            newLines.add('$assetsIndent  $assetLine'.replaceFirst('    ', ''));
            addedAsset = true;
            info('Registered asset in pubspec.yaml');
          }
        }
        // If we hit a non-asset line after finding assets section
        else if (!line.trim().startsWith('- ') &&
            !line.trim().startsWith('#') &&
            line.trim().isNotEmpty) {
          foundAssets = false;
        }
      }
    }

    // If we couldn't add the asset automatically
    if (!addedAsset) {
      comment('Could not auto-add to pubspec.yaml. Please add manually:');
      comment('  assets:');
      comment('    - assets/lang/$locale.json');
      return;
    }

    // Write the updated pubspec.yaml
    pubspecFile.writeAsStringSync(newLines.join('\n'));
  }

  /// Generate the initial JSON content.
  String _generateContent() {
    return '''
{
  "welcome": "Welcome, :name!",
  "auth": {
    "failed": "Authentication failed.",
    "throttle": "Too many attempts. Please try again in :seconds seconds."
  },
  "validation": {
    "required": "The :attribute field is required.",
    "email": "The :attribute must be a valid email address."
  }
}
''';
  }
}
