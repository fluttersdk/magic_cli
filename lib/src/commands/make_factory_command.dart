import 'dart:io';

import 'package:magic_cli/magic_cli.dart';

/// The Make Factory Command.
///
/// Scaffolds a new factory file using `.stub` templates.
///
/// ## Usage
///
/// ```bash
/// magic make:factory User
/// magic make:factory Post
/// ```
class MakeFactoryCommand extends Command {
  @override
  String get name => 'make:factory';

  @override
  String get description => 'Create a new factory class';

  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a model name.');
      error('Usage: magic make:factory <ModelName>');
      return;
    }

    final factoryInput = arguments.rest.first;
    // Strip 'Factory' suffix case-insensitively if present
    final modelName = factoryInput.toLowerCase().endsWith('factory')
        ? factoryInput.substring(0, factoryInput.length - 7)
        : factoryInput;
    final className = '${modelName}Factory';
    final snakeName = _toSnakeCase(modelName);
    final fileName = _toSnakeCase(className);

    // Create factories directory if it doesn't exist
    final dir = Directory('lib/database/factories');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/database/factories/');
    }

    // Check if file already exists
    final file = File('${dir.path}/$fileName.dart');
    if (file.existsSync()) {
      error('Factory already exists: ${file.path}');
      return;
    }

    // Generate file content using stub
    final content = _generateFromStub(modelName, className, snakeName);

    if (content.isEmpty) {
      error('Failed to generate factory content.');
      return;
    }

    // Write file
    file.writeAsStringSync(content);
    newLine();
    success('Created factory: lib/database/factories/$fileName.dart');
  }

  /// Convert PascalCase to snake_case.
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst('_', '');
  }

  /// Generate factory content from stub file.
  String _generateFromStub(
    String modelName,
    String className,
    String snakeName,
  ) {
    final replacements = <String, String>{
      'modelName': modelName,
      'className': className,
      'snakeName': snakeName,
    };

    try {
      return StubLoader.makeSync('factory', replacements);
    } on StubNotFoundException catch (e) {
      error('Error: ${e.toString()}');
      return '';
    }
  }
}
