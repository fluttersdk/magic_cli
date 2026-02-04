import 'dart:io';

import 'package:magic_cli/magic_cli.dart';

/// The Make View Command.
///
/// Scaffolds a new Magic view file using `.stub` templates.
///
/// ## Usage
///
/// ```bash
/// magic make:view Dashboard                    # Stateless view
/// magic make:view Auth/Login --stateful       # Stateful in subfolder
/// magic make:view Dashboard --responsive      # Responsive view
/// ```
///
/// ## Output
///
/// Creates a file in `lib/resources/views/` with nested folder support.
class MakeViewCommand extends Command {
  @override
  String get name => 'make:view';

  @override
  String get description => 'Create a new Magic view class';

  @override
  void configure(ArgParser parser) {
    parser.addFlag(
      'stateful',
      negatable: false,
      help: 'Create a stateful view with lifecycle hooks',
    );
    parser.addFlag(
      'responsive',
      abbr: 'r',
      negatable: false,
      help: 'Create a responsive view with mobile/tablet/desktop layouts',
    );
  }

  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a view name.');
      error('Usage: magic make:view <Path/Name> [--stateful] [--responsive]');
      return;
    }

    final input = arguments.rest.first;

    // Parse path and view name (e.g., "Auth/Register" -> folder: "auth", name: "Register")
    final parts = input.split('/');
    final rawName = parts.last;
    // Strip 'View' suffix case-insensitively if present
    final viewName = rawName.toLowerCase().endsWith('view')
        ? rawName.substring(0, rawName.length - 4)
        : rawName;
    final folderPath = parts.length > 1
        ? parts.sublist(0, parts.length - 1).map(_toSnakeCase).join('/')
        : '';

    // Validate view name (must be PascalCase starting with letter)
    if (!RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(viewName)) {
      error('View name must be PascalCase (e.g., Dashboard, UserProfile).');
      return;
    }

    final snakeName = _toSnakeCase(viewName);
    final fileName = '${snakeName}_view.dart';

    // Build full directory path
    final basePath = 'lib/resources/views';
    final dirPath = folderPath.isEmpty ? basePath : '$basePath/$folderPath';

    // Create views directory if it doesn't exist
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: $dirPath/');
    }

    // Check if file already exists
    final file = File('${dir.path}/$fileName');
    if (file.existsSync()) {
      error('View already exists: $dirPath/$fileName');
      return;
    }

    // Determine stub type
    final isStateful = arguments['stateful'] as bool? ?? false;
    final isResponsive = arguments['responsive'] as bool? ?? false;

    String stubName;
    if (isResponsive) {
      stubName = 'view.responsive';
    } else if (isStateful) {
      stubName = 'view.stateful';
    } else {
      stubName = 'view';
    }

    // Generate file content using stub
    final content = _generateFromStub(viewName, snakeName, stubName);

    if (content.isEmpty) {
      error('Failed to generate view content.');
      return;
    }

    // Write file
    file.writeAsStringSync(content);
    newLine();
    success('Created view: $dirPath/$fileName');
  }

  /// Convert PascalCase to snake_case.
  String _toSnakeCase(String input) {
    final result = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
        result.write('_');
      }
      result.write(char.toLowerCase());
    }
    return result.toString();
  }

  /// Generate view content from stub file.
  String _generateFromStub(
    String className,
    String snakeName,
    String stubName,
  ) {
    final replacements = <String, String>{
      'className': className,
      'snakeName': snakeName,
    };

    try {
      return StubLoader.makeSync(stubName, replacements);
    } on StubNotFoundException catch (e) {
      error('Error: ${e.toString()}');
      return '';
    }
  }
}
