import 'package:args/args.dart';
import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/stubs/migration_stubs.dart';
import 'package:path/path.dart' as path;

/// The Make Migration Command.
///
/// Scaffolds a new timestamped migration file inside `lib/database/migrations/`
/// using the `migrationCreateStub` (when `--create` is passed) or the plain
/// `migrationStub` otherwise.
///
/// ## Usage
///
/// ```bash
/// magic make:migration create_users_table
/// magic make:migration create_users_table --create=users
/// magic make:migration add_email_to_users --table=users
/// ```
///
/// ## Output
///
/// Creates a file named `m_YYYYMMDDHHMMSS_{name}.dart` in
/// `lib/database/migrations/`.
class MakeMigrationCommand extends GeneratorCommand {
  final String? _testRoot;
  MakeMigrationCommand({String? testRoot}) : _testRoot = testRoot;
  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();
  @override
  String get name => 'make:migration';

  @override
  String get description => 'Create a new migration file';

  @override
  String getDefaultNamespace() => 'lib/database/migrations';

  /// Adds the `--create` and `--table` options on top of the inherited
  /// `--force` flag registered by [GeneratorCommand.configure].
  @override
  void configure(ArgParser parser) {
    super.configure(parser);
    parser.addOption(
      'create',
      abbr: 'c',
      help: 'The table to be created (selects the create stub)',
    );
    parser.addOption(
      'table',
      abbr: 't',
      help: 'The table to migrate',
    );
  }

  /// Selects the create stub when `--create` is supplied, plain stub otherwise.
  @override
  String getStub() =>
      option('create') != null ? migrationCreateStub : migrationStub;

  /// Returns the default output namespace for migration files.
  ///
  /// Migration filenames carry a timestamp prefix: `m_YYYYMMDDHHMMSS_{name}.dart`.
  /// This overrides [GeneratorCommand.getPath] to inject that prefix.
  @override
  String getPath(String name) {
    final parsed = StringHelper.parseName(name);
    final projectRoot = getProjectRoot();
    final namespace = getDefaultNamespace();

    // 1. Build the timestamp-prefixed filename.
    final timestamp = _buildTimestamp();
    final snakeName = StringHelper.toSnakeCase(parsed.className);
    final fileName = 'm_${timestamp}_$snakeName.dart';

    // 2. Respect nested directory if the user passed a slash-separated path.
    if (parsed.directory.isEmpty) {
      return path.join(projectRoot, namespace, fileName);
    }

    return path.join(projectRoot, namespace, parsed.directory, fileName);
  }

  /// Provides placeholder replacements for the migration stub.
  ///
  /// - `{{ className }}` — timestamped PascalCase class identifier.
  /// - `{{ fullName }}` — snake_case timestamp+name (used as migration `name`).
  /// - `{{ tableName }}` — the target table name (from `--create`, `--table`,
  ///   or derived from the migration name).
  @override
  Map<String, String> getReplacements(String name) {
    final timestamp = _buildTimestamp();
    final snakeName = StringHelper.toSnakeCase(
      StringHelper.parseName(name).className,
    );
    final fullName = '${timestamp}_$snakeName';

    // Derive table name: --create > --table > snake_name without verb wrapper.
    final tableName = option('create') ??
        option('table') ??
        StringHelper.toSnakeCase(StringHelper.parseName(name).className);

    // Build PascalCase class name from the full timestamp+name.
    final className = StringHelper.toPascalCase(fullName);

    return {
      '{{ className }}': className,
      '{{ fullName }}': fullName,
      '{{ tableName }}': tableName,
    };
  }

  /// Produces a compact 14-digit timestamp string `YYYYMMDDHHmmss`.
  String _buildTimestamp() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }
}
