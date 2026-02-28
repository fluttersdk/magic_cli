import 'package:args/args.dart';
import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:path/path.dart' as path;

/// The `make:policy` generator command.
///
/// Scaffolds a new authorization policy class inside `lib/app/policies/`,
/// extending the Magic `Policy` base and registering `Gate.define` callbacks.
///
/// ## Usage
///
/// ```bash
/// magic make:policy Monitor               # → MonitorPolicy
/// magic make:policy MonitorPolicy         # Suffix already present — no double-append
/// magic make:policy Monitor --model=Monitor
/// magic make:policy Admin/Dashboard       # Nested path support
/// magic make:policy Monitor --force       # Overwrite existing file
/// ```
class MakePolicyCommand extends GeneratorCommand {
  /// Optional project root override — injected in tests to avoid touching the
  /// real filesystem.
  final String? _testRoot;

  /// Creates a [MakePolicyCommand].
  ///
  /// Pass [testRoot] to pin the project root to a temp directory during tests.
  MakePolicyCommand({String? testRoot}) : _testRoot = testRoot;

  @override
  String get name => 'make:policy';

  @override
  String get description => 'Create a new policy class';

  @override
  String getDefaultNamespace() => 'lib/app/policies';

  @override
  String getStub() => 'policy';

  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();

  @override
  void configure(ArgParser parser) {
    super.configure(parser);
    parser.addOption(
      'model',
      abbr: 'm',
      help: 'The model the policy applies to',
    );
  }

  /// Override to produce the Policy-suffixed file name as the output path.
  ///
  /// The default [getPath] uses [parsed.fileName] which maps `Monitor` →
  /// `monitor.dart`; we need `monitor_policy.dart`.
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

  /// Override to inject the Policy-suffixed class name so [buildClass] uses the
  /// correct value before [getReplacements] runs.
  @override
  String replaceClass(String stub, String name) {
    return stub.replaceAll('{{ className }}', _resolveClassName(name));
  }

  @override
  Map<String, String> getReplacements(String name) {
    final className = _resolveClassName(name);

    // Model name: from --model option, or inferred by removing 'Policy' suffix.
    final modelName =
        option('model') as String? ?? className.replaceAll('Policy', '');
    final modelSnakeName = StringHelper.toSnakeCase(modelName);

    return {
      '{{ snakeName }}': StringHelper.toSnakeCase(className),
      '{{ modelSnakeName }}': modelSnakeName,
      '{{ modelClass }}': modelName,
      '{{ modelName }}': modelName,
    };
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Returns the class name with 'Policy' suffix guaranteed.
  ///
  /// When [name] already ends with 'Policy' (e.g. 'MonitorPolicy'), the input
  /// is returned unchanged; otherwise 'Policy' is appended.
  String _resolveClassName(String name) {
    final parsed = StringHelper.parseName(name);
    return parsed.className.endsWith('Policy')
        ? parsed.className
        : '${parsed.className}Policy';
  }
}
