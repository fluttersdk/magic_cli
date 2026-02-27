import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/stubs/seeder_stubs.dart';

/// The Make Seeder Command.
///
/// Scaffolds a new database seeder inside `lib/database/seeders/`.
/// Automatically appends the `Seeder` suffix when the caller omits it.
///
/// ## Usage
///
/// ```bash
/// magic make:seeder User         # → UserSeeder in user_seeder.dart
/// magic make:seeder UserSeeder   # Same result — no double-suffix
/// ```
class MakeSeederCommand extends GeneratorCommand {
  final String? _testRoot;
  MakeSeederCommand({String? testRoot}) : _testRoot = testRoot;
  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();
  @override
  String get name => 'make:seeder';

  @override
  String get description => 'Create a new seeder class';

  @override
  String getDefaultNamespace() => 'lib/database/seeders';

  /// Always returns the seeder stub.
  @override
  String getStub() => seederStub;

  /// Normalises [name] so it always carries the `Seeder` suffix.
  ///
  /// Operates only on the last path segment, preserving nested directories.
  String _normalizeName(String name) {
    final parsed = StringHelper.parseName(name);
    final className = parsed.className.endsWith('Seeder')
        ? parsed.className
        : '${parsed.className}Seeder';

    return parsed.directory.isEmpty
        ? className
        : '${parsed.directory}/$className';
  }

  /// Overrides [GeneratorCommand.getPath] to apply the suffix-corrected name.
  @override
  String getPath(String name) => super.getPath(_normalizeName(name));

  /// Overrides [GeneratorCommand.buildClass] to apply the suffix-corrected name.
  ///
  /// Ensures [replaceClass] fills `{{ className }}` with the full
  /// `Seeder`-suffixed class name, not the raw user input.
  @override
  String buildClass(String name) => super.buildClass(_normalizeName(name));

  /// Provides the remaining placeholder replacements for the seeder stub.
  ///
  /// `{{ className }}` is handled upstream by [buildClass] normalisation.
  /// Here we only supply `{{ snakeName }}` for the model factory comment.
  @override
  Map<String, String> getReplacements(String name) {
    // [name] is already normalised (Seeder-suffixed) at this point.
    final parsed = StringHelper.parseName(name);
    final snakeName = StringHelper.toSnakeCase(parsed.className);
    final modelName = parsed.className.replaceAll('Seeder', '');

    return {
      '{{ snakeName }}': snakeName,
      '{{ modelName }}': modelName,
    };
  }
}
