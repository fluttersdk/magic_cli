import 'dart:io';

import 'package:fluttersdk_magic_cli/src/console/command.dart';
import 'package:fluttersdk_magic_cli/src/stubs/stub_loader.dart';

/// The Make Seeder Command.
///
/// Scaffolds a new seeder file using `.stub` templates.
///
/// ## Usage
///
/// ```bash
/// magic make:seeder UserSeeder
/// magic make:seeder User          # Automatically appends 'Seeder'
/// ```
class MakeSeederCommand extends Command {
  @override
  String get name => 'make:seeder';

  @override
  String get description => 'Create a new seeder class';

  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a seeder name.');
      error('Usage: magic make:seeder <name>');
      return;
    }

    final seederName = arguments.rest.first;
    // Strip 'Seeder' suffix case-insensitively if present
    final modelName = seederName.toLowerCase().endsWith('seeder')
        ? seederName.substring(0, seederName.length - 6)
        : seederName;
    final className = '${modelName}Seeder';
    final fileName = _toSnakeCase(className);

    // Create seeders directory if it doesn't exist
    final dir = Directory('lib/database/seeders');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/database/seeders/');
    }

    // Check if file already exists
    final file = File('${dir.path}/$fileName.dart');
    if (file.existsSync()) {
      error('Seeder already exists: ${file.path}');
      return;
    }

    // Generate file content using stub
    final content = _generateFromStub(className, modelName);

    if (content.isEmpty) {
      error('Failed to generate seeder content.');
      return;
    }

    // Write file
    file.writeAsStringSync(content);
    info('Created seeder: lib/database/seeders/$fileName.dart');
  }

  /// Convert PascalCase to snake_case.
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst('_', '');
  }

  /// Generate seeder content from stub file.
  String _generateFromStub(String className, String modelName) {
    final replacements = <String, String>{
      'className': className,
      'modelName': modelName,
    };

    try {
      return StubLoader.makeSync('seeder', replacements);
    } on StubNotFoundException catch (e) {
      error('Error: ${e.toString()}');
      return '';
    }
  }
}
