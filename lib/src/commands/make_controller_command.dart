import 'package:args/args.dart';
import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/helpers/file_helper.dart';

/// The `magic make:controller` generator command.
///
/// Scaffolds a new MagicController class using the controller stub templates.
///
/// ## Usage
///
/// ```bash
/// magic make:controller Monitor            # → lib/app/controllers/monitor_controller.dart
/// magic make:controller Admin/Dashboard    # → lib/app/controllers/admin/dashboard_controller.dart
/// magic make:controller Monitor --resource # → Resource controller with CRUD methods
/// ```
///
/// The `Controller` suffix is appended automatically when omitted.
class MakeControllerCommand extends GeneratorCommand {
  /// Optional test root override — enables isolation in unit tests.
  final String? _testRoot;

  /// Creates a [MakeControllerCommand].
  ///
  /// [testRoot] overrides the project root resolution, used in tests only.
  MakeControllerCommand({String? testRoot}) : _testRoot = testRoot;

  @override
  String get name => 'make:controller';

  @override
  String get description => 'Create a new controller class';

  @override
  String getDefaultNamespace() => 'lib/app/controllers';

  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();

  @override
  void configure(ArgParser parser) {
    // 1. Register --force (and base args) from parent first.
    super.configure(parser);

    // 2. Add controller-specific flags.
    parser.addFlag(
      'resource',
      abbr: 'r',
      help: 'Generate a resource controller with CRUD methods',
      negatable: false,
    );
    parser.addOption(
      'model',
      abbr: 'm',
      help: 'The model the controller applies to',
    );
  }

  @override
  String getStub() =>
      hasOption('resource') ? 'controller.resource' : 'controller';

  /// Provides extra placeholder replacements for the controller stub.
  ///
  /// [name] is the BASE name without the `Controller` suffix
  /// (e.g., `Monitor`, `Admin/Dashboard`).
  @override
  Map<String, String> getReplacements(String name) {
    final parsed = StringHelper.parseName(name);
    return {
      '{{ snakeName }}': StringHelper.toSnakeCase(parsed.className),
    };
  }

  @override
  Future<void> handle() async {
    final rawName = argument(0);
    if (rawName == null || rawName.isEmpty) {
      error('Not enough arguments (missing: "name").');
      return;
    }

    // 1. Derive base name (no Controller suffix) and full name (with suffix).
    final baseName = _stripSuffix(rawName, 'Controller');
    final fullName = _withSuffix(rawName, 'Controller');

    // 2. Resolve output path using the FULL name so filename is correct
    //    (e.g., MonitorController → monitor_controller.dart).
    final filePath = getPath(fullName);

    // 3. Abort if file exists and --force was not provided.
    if (FileHelper.fileExists(filePath) && !hasOption('force')) {
      error('File already exists at $filePath');
      return;
    }

    // 4. Build stub content using the BASE name so {{ className }} resolves
    //    correctly — the stub appends "Controller" to the placeholder itself.
    final content = buildClass(baseName);
    FileHelper.writeFile(filePath, content);

    success('Created: $filePath');
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  /// Returns [name] with [suffix] appended to the last path segment if absent.
  ///
  /// Handles nested paths: `Admin/Dashboard` → `Admin/DashboardController`.
  String _withSuffix(String name, String suffix) {
    final parts = name.split('/');
    final last = parts.last;
    final normalisedLast = last.endsWith(suffix) ? last : '$last$suffix';
    return [...parts.sublist(0, parts.length - 1), normalisedLast].join('/');
  }

  /// Returns [name] with [suffix] removed from the last path segment if present.
  ///
  /// Handles nested paths: `Admin/DashboardController` → `Admin/Dashboard`.
  String _stripSuffix(String name, String suffix) {
    final parts = name.split('/');
    final last = parts.last;
    final strippedLast = last.endsWith(suffix)
        ? last.substring(0, last.length - suffix.length)
        : last;
    return [...parts.sublist(0, parts.length - 1), strippedLast].join('/');
  }
}
