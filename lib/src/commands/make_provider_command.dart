import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';

/// Make Provider Command.
///
/// Scaffolds a new Magic service provider class using the [providerStub] template.
/// Automatically appends `ServiceProvider` suffix when not already present.
///
/// ## Usage
///
/// ```bash
/// magic make:provider App              # → AppServiceProvider
/// magic make:provider AppServiceProvider  # → AppServiceProvider (no double suffix)
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/providers/` with `register()` and `boot()` stubs.
class MakeProviderCommand extends GeneratorCommand {
  @override
  String get name => 'make:provider';

  @override
  String get description => 'Create a new service provider class';

  @override
  String getDefaultNamespace() => 'lib/app/providers';

  @override
  String getStub() => 'provider';

  /// Returns placeholder replacements for the provider stub.
  ///
  /// Replaces `{{ snakeName }}` and `{{ description }}`. The `{{ className }}`
  /// placeholder is handled by the overridden [replaceClass].
  @override
  Map<String, String> getReplacements(String name) {
    final className = _resolveClassName(name);

    // 1. Derive snake_case identifier from the final class name.
    final snakeName = StringHelper.toSnakeCase(className);

    // 2. Build a human-readable description from the base name.
    final baseName = className.replaceAll('ServiceProvider', '');
    final description =
        '${StringHelper.toSnakeCase(baseName).replaceAll('_', ' ')} services';

    return {
      '{{ snakeName }}': snakeName,
      '{{ description }}': description,
    };
  }

  /// Overrides className replacement to use the ServiceProvider-suffixed name.
  ///
  /// The base [GeneratorCommand.replaceClass] uses the raw parsed class name.
  /// Providers need the suffixed name substituted instead.
  @override
  String replaceClass(String stub, String name) {
    return stub.replaceAll('{{ className }}', _resolveClassName(name));
  }

  /// Resolves the final class name — appending `ServiceProvider` when absent.
  String _resolveClassName(String name) {
    final parsed = StringHelper.parseName(name);

    return parsed.className.endsWith('ServiceProvider')
        ? parsed.className
        : '${parsed.className}ServiceProvider';
  }

  /// Overrides the default path to use the ServiceProvider-suffixed class name.
  ///
  /// The base [GeneratorCommand.getPath] uses `parseName(name).fileName`
  /// directly. For providers we need the final (potentially suffixed) class
  /// name to determine the file name.
  @override
  String getPath(String name) {
    final parsed = StringHelper.parseName(name);

    // Resolve the final class name with ServiceProvider suffix.
    final className = parsed.className.endsWith('ServiceProvider')
        ? parsed.className
        : '${parsed.className}ServiceProvider';

    final fileName = StringHelper.toSnakeCase(className);
    final namespace = getDefaultNamespace();
    final projectRoot = getProjectRoot();

    if (parsed.directory.isEmpty) {
      return '$projectRoot/$namespace/$fileName.dart';
    }

    return '$projectRoot/$namespace/${parsed.directory}/$fileName.dart';
  }
}
