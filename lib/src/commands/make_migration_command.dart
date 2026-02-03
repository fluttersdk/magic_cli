import 'dart:io';

import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';

/// The Make Migration Command.
///
/// Scaffolds a new migration file with the proper naming convention and
/// boilerplate code using `.stub` templates.
///
/// ## Usage
///
/// ```bash
/// magic make:migration create_users_table
/// magic make:migration CreateUsersTable
/// ```
///
/// ## Output
///
/// Creates a file in `lib/database/migrations/` with:
/// - Timestamp-prefixed filename (snake_case)
/// - Migration class with up/down methods
/// - Proper imports
class MakeMigrationCommand extends Command {
  @override
  String get name => 'make:migration';

  @override
  String get description => 'Create a new migration file';

  /// Execute the console command.
  @override
  Future<void> handle() async {
    // Get the migration name from arguments
    if (arguments.rest.isEmpty) {
      error('Please provide a migration name.');
      error('Usage: magic make:migration <name>');
      return;
    }

    final inputName = arguments.rest.first;

    // Normalize to snake_case for file naming
    final migrationName = _toSnakeCase(inputName);

    // Generate timestamp prefix
    final now = DateTime.now();
    final timestamp = '${now.year}_'
        '${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // Generate class name (PascalCase)
    final className = _toPascalCase(migrationName);

    // Full migration identifier (used internally for tracking)
    final fullName = '${timestamp}_$migrationName';

    // Filename with 'm_' prefix for Dart lint compliance
    final fileName = 'm_$fullName.dart';

    // Create migrations directory if it doesn't exist
    final dir = Directory('lib/database/migrations');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/database/migrations/');
    }

    // Detect if this is a create table migration
    final isCreate =
        migrationName.startsWith('create_') && migrationName.endsWith('_table');

    // Generate file content using stubs
    final content =
        _generateFromStub(fullName, className, migrationName, isCreate);

    if (content.isEmpty) {
      error('Failed to generate migration content.');
      return;
    }

    // Write file
    final file = File('${dir.path}/$fileName');
    file.writeAsStringSync(content);

    newLine();
    success('Created migration: lib/database/migrations/$fileName');
  }

  /// Convert PascalCase or camelCase to snake_case.
  String _toSnakeCase(String input) {
    // If already snake_case, return as is
    if (input.contains('_') && input == input.toLowerCase()) {
      return input;
    }

    // Convert PascalCase/camelCase to snake_case
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), ''); // Remove leading underscore
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

  /// Generate migration content from stub files.
  String _generateFromStub(
    String fullName,
    String className,
    String migrationName,
    bool isCreate,
  ) {
    // Select appropriate stub
    final stubName = isCreate ? 'migration.create' : 'migration';

    // Build replacements map
    final replacements = <String, String>{
      'fullName': fullName,
      'className': className,
    };

    // Add table name for create migrations
    if (isCreate) {
      final tableName =
          migrationName.replaceFirst('create_', '').replaceFirst('_table', '');
      replacements['tableName'] = tableName;
    }

    // Load and process stub
    try {
      return StubLoader.makeSync(stubName, replacements);
    } on StubNotFoundException catch (e) {
      error('Error: ${e.toString()}');
      return '';
    }
  }
}
