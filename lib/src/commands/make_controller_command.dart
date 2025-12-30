import 'dart:io';

import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/src/console/command.dart';
import 'package:fluttersdk_magic_cli/src/stubs/stub_loader.dart';

/// The Make Controller Command.
///
/// Scaffolds a new Magic controller file using `.stub` templates.
///
/// ## Usage
///
/// ```bash
/// magic make:controller User                   # Basic controller
/// magic make:controller Todo --stateful       # With MagicStateMixin
/// magic make:controller Product --resource    # CRUD with views
/// magic make:controller Admin/Dashboard       # Nested folder
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/controllers/` with nested folder support.
class MakeControllerCommand extends Command {
  @override
  String get name => 'make:controller';

  @override
  String get description => 'Create a new Magic controller class';

  @override
  void configure(ArgParser parser) {
    parser.addFlag(
      'stateful',
      abbr: 's',
      negatable: false,
      help: 'Create a controller with MagicStateMixin for state management',
    );
    parser.addFlag(
      'resource',
      abbr: 'r',
      negatable: false,
      help: 'Create a resource controller with CRUD actions and views',
    );
  }

  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a controller name.');
      error(
          'Usage: magic make:controller <Path/Name> [--stateful] [--resource]');
      return;
    }

    final input = arguments.rest.first;

    // Parse path and controller name
    final parts = input.split('/');
    final rawName = parts.last;
    // Strip 'Controller' suffix case-insensitively if present
    final controllerName = rawName.toLowerCase().endsWith('controller')
        ? rawName.substring(0, rawName.length - 10)
        : rawName;
    final folderPath = parts.length > 1
        ? parts.sublist(0, parts.length - 1).map(_toSnakeCase).join('/')
        : '';

    // Validate controller name
    if (!RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(controllerName)) {
      error('Controller name must be PascalCase (e.g., User, Dashboard).');
      return;
    }

    final snakeName = _toSnakeCase(controllerName);
    final fileName = '${snakeName}_controller.dart';

    // Build full directory path
    final basePath = 'lib/app/controllers';
    final dirPath = folderPath.isEmpty ? basePath : '$basePath/$folderPath';

    // Create controllers directory
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: $dirPath/');
    }

    // Check if file already exists
    final file = File('${dir.path}/$fileName');
    if (file.existsSync()) {
      error('Controller already exists: $dirPath/$fileName');
      return;
    }

    // Determine stub type
    final isStateful = arguments['stateful'] as bool? ?? false;
    final isResource = arguments['resource'] as bool? ?? false;

    String stubName;
    if (isResource) {
      stubName = 'controller.resource';
    } else if (isStateful) {
      stubName = 'controller.stateful';
    } else {
      stubName = 'controller';
    }

    // Generate file content
    final content = _generateFromStub(controllerName, snakeName, stubName);

    if (content.isEmpty) {
      error('Failed to generate controller content.');
      return;
    }

    // Write file
    file.writeAsStringSync(content);
    info('Created controller: $dirPath/$fileName');

    // If resource, create CRUD views
    if (isResource) {
      await _createResourceViews(controllerName, snakeName);
    }
  }

  /// Create resource CRUD views using stateful stub pattern.
  Future<void> _createResourceViews(String className, String snakeName) async {
    final viewTypes = ['index', 'show', 'create', 'edit'];
    final viewsDir = 'lib/resources/views/$snakeName';

    // Create views directory
    final dir = Directory(viewsDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: $viewsDir/');
    }

    for (final viewType in viewTypes) {
      final fileName = '${viewType}_view.dart';
      final file = File('$viewsDir/$fileName');

      if (file.existsSync()) {
        comment('View already exists: $viewsDir/$fileName');
        continue;
      }

      // Use view.stateful stub with proper class name (e.g., ProductTypeIndex)
      final viewClassName =
          '$className${viewType[0].toUpperCase()}${viewType.substring(1)}';
      try {
        final content = StubLoader.makeSync('view.stateful', {
          'className': viewClassName,
          'modelName': className,
          'snakeName': snakeName,
        });
        file.writeAsStringSync(content);
        info('Created view: $viewsDir/$fileName');
      } on StubNotFoundException {
        error('Stub not found: view.stateful.stub');
      }
    }
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

  /// Generate controller content from stub file.
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
