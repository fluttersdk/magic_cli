import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/stubs/request_stubs.dart';
import 'package:path/path.dart' as path;

/// The `make:request` generator command.
///
/// Scaffolds a new form-request class inside `lib/app/validation/requests/`,
/// containing a typed `rules()` method for request validation.
///
/// ## Usage
///
/// ```bash
/// magic make:request StoreMonitor             # → StoreMonitorRequest
/// magic make:request StoreMonitorRequest      # Suffix already present — no double-append
/// magic make:request StoreMonitor --force     # Overwrite existing file
/// ```
class MakeRequestCommand extends GeneratorCommand {
  /// Optional project root override — injected in tests to avoid touching the
  /// real filesystem.
  final String? _testRoot;

  /// Creates a [MakeRequestCommand].
  ///
  /// Pass [testRoot] to pin the project root to a temp directory during tests.
  MakeRequestCommand({String? testRoot}) : _testRoot = testRoot;

  @override
  String get name => 'make:request';

  @override
  String get description => 'Create a new form request class';

  @override
  String getDefaultNamespace() => 'lib/app/validation/requests';

  @override
  String getStub() => requestStub;

  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();

  /// Override to produce the Request-suffixed file name as the output path.
  ///
  /// The default [getPath] uses [parsed.fileName] which maps `StoreMonitor` →
  /// `store_monitor.dart`; we need `store_monitor_request.dart`.
  @override
  String getPath(String name) {
    final parsed = StringHelper.parseName(name);
    final className = _resolveClassName(name);
    final fileName = StringHelper.toSnakeCase(className);
    final namespace = getDefaultNamespace();
    final projectRoot = getProjectRoot();

    if (parsed.directory.isEmpty) {
      return path.join(projectRoot, namespace, '$fileName.dart');
    }

    return path.join(
        projectRoot, namespace, parsed.directory, '$fileName.dart');
  }

  /// Override to inject the Request-suffixed class name so [buildClass] uses
  /// the correct value before [getReplacements] runs.
  @override
  String replaceClass(String stub, String name) {
    return stub.replaceAll('{{ className }}', _resolveClassName(name));
  }

  @override
  Map<String, String> getReplacements(String name) {
    final className = _resolveClassName(name);

    return {
      '{{ snakeName }}': StringHelper.toSnakeCase(className),
      '{{ actionDescription }}': _toHumanReadable(className),
    };
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Returns the class name with 'Request' suffix guaranteed.
  ///
  /// When [name] already ends with 'Request' (e.g. 'StoreMonitorRequest'),
  /// the input is returned unchanged; otherwise 'Request' is appended.
  String _resolveClassName(String name) {
    final parsed = StringHelper.parseName(name);
    return parsed.className.endsWith('Request')
        ? parsed.className
        : '${parsed.className}Request';
  }

  /// Converts a PascalCase class name (with 'Request' stripped) to a
  /// human-readable action description for stub docblocks.
  ///
  /// Example: `StoreMonitorRequest` → `store monitor`
  String _toHumanReadable(String className) {
    final withoutSuffix = className.replaceAll('Request', '');
    return StringHelper.toSnakeCase(withoutSuffix).replaceAll('_', ' ');
  }
}
