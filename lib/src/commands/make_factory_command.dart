import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/stubs/factory_stubs.dart';

/// The Make Factory Command.
///
/// Scaffolds a new model factory inside `lib/database/factories/`.
/// Automatically appends the `Factory` suffix when the caller omits it.
///
/// ## Usage
///
/// ```bash
/// magic make:factory User         # → UserFactory in user_factory.dart
/// magic make:factory UserFactory  # Same result — no double-suffix
/// ```
class MakeFactoryCommand extends GeneratorCommand {
  final String? _testRoot;
  MakeFactoryCommand({String? testRoot}) : _testRoot = testRoot;
  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();
  @override
  String get name => 'make:factory';

  @override
  String get description => 'Create a new factory class';

  @override
  String getDefaultNamespace() => 'lib/database/factories';

  /// Always returns the factory stub.
  @override
  String getStub() => factoryStub;

  /// Normalises [name] so it always carries the `Factory` suffix.
  ///
  /// Operates only on the last path segment, preserving nested directories.
  String _normalizeName(String name) {
    final parsed = StringHelper.parseName(name);
    final className = parsed.className.endsWith('Factory')
        ? parsed.className
        : '${parsed.className}Factory';

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
  /// `Factory`-suffixed class name, not the raw user input.
  @override
  String buildClass(String name) => super.buildClass(_normalizeName(name));

  /// Provides the remaining placeholder replacements for the factory stub.
  ///
  /// `{{ className }}` is filled upstream by [buildClass] normalisation.
  /// Here we supply `{{ modelName }}` and `{{ snakeName }}` for the stub body.
  @override
  Map<String, String> getReplacements(String name) {
    // [name] is already normalised (Factory-suffixed) at this point.
    final parsed = StringHelper.parseName(name);

    // Model name = class name without the 'Factory' suffix.
    final modelName = parsed.className.substring(
      0,
      parsed.className.length - 7,
    );
    final snakeName = StringHelper.toSnakeCase(modelName);

    return {
      '{{ modelName }}': modelName,
      '{{ snakeName }}': snakeName,
    };
  }
}
