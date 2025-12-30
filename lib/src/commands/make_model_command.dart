import 'dart:io';

import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/src/console/command.dart';
import 'package:fluttersdk_magic_cli/src/stubs/stub_loader.dart';

/// The Make Model Command.
///
/// Scaffolds a new Eloquent model file with proper boilerplate code
/// using `.stub` templates.
///
/// ## Usage
///
/// ```bash
/// magic make:model User
/// magic make:model Post -m        # Also create migration
/// magic make:model Order --migration
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/models/` with:
/// - Model class extending Model with HasTimestamps and InteractsWithPersistence
/// - Table and resource configuration
/// - Typed accessor stubs
class MakeModelCommand extends Command {
  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new Eloquent model class';

  @override
  void configure(ArgParser parser) {
    parser.addFlag(
      'migration',
      abbr: 'm',
      negatable: false,
      help: 'Create a new migration file for the model',
    );
    parser.addFlag(
      'seed',
      abbr: 's',
      negatable: false,
      help: 'Create a new seeder file for the model',
    );
    parser.addFlag(
      'factory',
      abbr: 'f',
      negatable: false,
      help: 'Create a new factory file for the model',
    );
    parser.addFlag(
      'controller',
      abbr: 'c',
      negatable: false,
      help: 'Create a new controller for the model',
    );
    parser.addFlag(
      'resource',
      abbr: 'r',
      negatable: false,
      help: 'Create a resource controller with CRUD views',
    );
    parser.addFlag(
      'all',
      abbr: 'a',
      negatable: false,
      help:
          'Create migration, seeder, factory, policy, and resource controller',
    );
  }

  /// Execute the console command.
  @override
  Future<void> handle() async {
    // Get the model name from arguments
    if (arguments.rest.isEmpty) {
      error('Please provide a model name.');
      error('Usage: magic make:model <name> [-m] [-s] [-f]');
      return;
    }

    final modelName = arguments.rest.first;

    // Validate model name (must be PascalCase starting with letter)
    if (!RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(modelName)) {
      error('Model name must be PascalCase (e.g., User, BlogPost).');
      return;
    }

    // Generate snake_case filename and table name
    final snakeName = _toSnakeCase(modelName);
    final fileName = '$snakeName.dart';
    final tableName = '${snakeName}s'; // Simple pluralization

    // Create models directory if it doesn't exist
    final dir = Directory('lib/app/models');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/app/models/');
    }

    // Check if file already exists
    final file = File('${dir.path}/$fileName');
    if (file.existsSync()) {
      error('Model already exists: lib/app/models/$fileName');
      return;
    }

    // Generate file content using stub
    final content = _generateFromStub(modelName, tableName, snakeName);

    if (content.isEmpty) {
      error('Failed to generate model content.');
      return;
    }

    // Write file
    file.writeAsStringSync(content);
    info('Created model: lib/app/models/$fileName');

    // Check for --all flag first
    final createAll = arguments['all'] as bool? ?? false;

    // Check for migration flag
    final createMigration =
        createAll || (arguments['migration'] as bool? ?? false);
    if (createMigration) {
      await _createMigration(tableName);
    }

    // Check for seed flag
    final createSeeder = createAll || (arguments['seed'] as bool? ?? false);
    if (createSeeder) {
      await _createSeeder(modelName);
    }

    // Check for factory flag
    final createFactory = createAll || (arguments['factory'] as bool? ?? false);
    if (createFactory) {
      await _createFactory(modelName);
    }

    // Check for policy (only with --all)
    if (createAll) {
      await _createPolicy(modelName, snakeName);
    }

    // Check for controller flags
    final createController = arguments['controller'] as bool? ?? false;
    final createResource =
        createAll || (arguments['resource'] as bool? ?? false);
    if (createResource) {
      await _createController(modelName, snakeName, isResource: true);
    } else if (createController) {
      await _createController(modelName, snakeName, isResource: false);
    }
  }

  /// Create a migration for the model's table.
  Future<void> _createMigration(String tableName) async {
    final migrationName = 'create_${tableName}_table';

    // Generate timestamp prefix
    final now = DateTime.now();
    final timestamp = '${now.year}_'
        '${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final className = _toPascalCase(migrationName);
    final fullName = '${timestamp}_$migrationName';
    final fileName = 'm_$fullName.dart';

    // Create migrations directory
    final dir = Directory('lib/database/migrations');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/database/migrations/');
    }

    // Generate migration content using stub
    final replacements = <String, String>{
      'fullName': fullName,
      'className': className,
      'tableName':
          tableName.replaceFirst('_table', '').replaceFirst(RegExp(r's$'), ''),
    };

    String content;
    try {
      content = StubLoader.makeSync('migration.create', replacements);
    } on StubNotFoundException {
      error('Migration stub not found.');
      return;
    }

    // Write migration file
    final file = File('${dir.path}/$fileName');
    file.writeAsStringSync(content);
    info('Created migration: lib/database/migrations/$fileName');
  }

  /// Create a seeder for the model.
  Future<void> _createSeeder(String modelName) async {
    final className = '${modelName}Seeder';
    final fileName = _toSnakeCase(className);

    // Create seeders directory
    final dir = Directory('lib/database/seeders');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/database/seeders/');
    }

    // Generate seeder content using stub
    final replacements = <String, String>{
      'className': className,
      'modelName': modelName,
    };

    String content;
    try {
      content = StubLoader.makeSync('seeder', replacements);
    } on StubNotFoundException {
      error('Seeder stub not found.');
      return;
    }

    // Write seeder file
    final file = File('${dir.path}/$fileName.dart');
    file.writeAsStringSync(content);
    info('Created seeder: lib/database/seeders/$fileName.dart');
  }

  /// Create a factory for the model.
  Future<void> _createFactory(String modelName) async {
    final className = '${modelName}Factory';
    final snakeName = _toSnakeCase(modelName);
    final fileName = _toSnakeCase(className);

    // Create factories directory
    final dir = Directory('lib/database/factories');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/database/factories/');
    }

    // Generate factory content using stub
    final replacements = <String, String>{
      'modelName': modelName,
      'className': className,
      'snakeName': snakeName,
    };

    String content;
    try {
      content = StubLoader.makeSync('factory', replacements);
    } on StubNotFoundException {
      error('Factory stub not found.');
      return;
    }

    // Write factory file
    final file = File('${dir.path}/$fileName.dart');
    file.writeAsStringSync(content);
    info('Created factory: lib/database/factories/$fileName.dart');
  }

  /// Create a policy for the model.
  Future<void> _createPolicy(String modelName, String snakeName) async {
    final className = '${modelName}Policy';
    final fileName = '${snakeName}_policy.dart';

    // Create policies directory
    final dir = Directory('lib/app/policies');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/app/policies/');
    }

    // Check if file exists
    final file = File('${dir.path}/$fileName');
    if (file.existsSync()) {
      comment('Policy already exists: lib/app/policies/$fileName');
      return;
    }

    // Generate policy content
    final camelName = modelName[0].toLowerCase() + modelName.substring(1);
    final replacements = <String, String>{
      'className': className,
      'modelName': modelName,
      'snakeName': snakeName,
      'camelName': camelName,
    };

    String content;
    try {
      content = StubLoader.makeSync('policy', replacements);
    } on StubNotFoundException {
      error('Policy stub not found.');
      return;
    }

    // Write policy file
    file.writeAsStringSync(content);
    info('Created policy: lib/app/policies/$fileName');
  }

  /// Create a controller for the model.
  Future<void> _createController(
    String modelName,
    String snakeName, {
    required bool isResource,
  }) async {
    final className = modelName;
    final fileName = '${snakeName}_controller.dart';

    // Create controllers directory
    final dir = Directory('lib/app/controllers');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/app/controllers/');
    }

    // Check if file exists
    final file = File('${dir.path}/$fileName');
    if (file.existsSync()) {
      comment('Controller already exists: lib/app/controllers/$fileName');
      return;
    }

    // Determine stub type
    final stubName = isResource ? 'controller.resource' : 'controller.stateful';

    // Generate controller content
    final replacements = <String, String>{
      'className': className,
      'snakeName': snakeName,
    };

    String content;
    try {
      content = StubLoader.makeSync(stubName, replacements);
    } on StubNotFoundException {
      error('Controller stub not found.');
      return;
    }

    // Write controller file
    file.writeAsStringSync(content);
    info('Created controller: lib/app/controllers/$fileName');

    // If resource, also create CRUD views
    if (isResource) {
      await _createResourceViews(className, snakeName);
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

  /// Convert snake_case to PascalCase.
  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join('');
  }

  /// Generate model content from stub file.
  String _generateFromStub(
    String className,
    String tableName,
    String resourceName,
  ) {
    final replacements = <String, String>{
      'className': className,
      'tableName': tableName,
      'resourceName': resourceName,
    };

    try {
      return StubLoader.makeSync('model', replacements);
    } on StubNotFoundException catch (e) {
      error('Error: ${e.toString()}');
      return '';
    }
  }
}
