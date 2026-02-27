import 'package:args/args.dart';
import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/helpers/file_helper.dart';
import 'package:magic_cli/src/stubs/view_stubs.dart';

/// The `magic make:view` generator command.
///
/// Scaffolds a new MagicView class using the view stub templates.
///
/// ## Usage
///
/// ```bash
/// magic make:view Login              # → lib/resources/views/login_view.dart
/// magic make:view Auth/Register      # → lib/resources/views/auth/register_view.dart
/// magic make:view Dashboard --stateful  # → Stateful view with lifecycle hooks
/// ```
///
/// The `View` suffix is appended automatically when omitted.
class MakeViewCommand extends GeneratorCommand {
  /// Optional test root override — enables isolation in unit tests.
  final String? _testRoot;

  /// Creates a [MakeViewCommand].
  ///
  /// [testRoot] overrides the project root resolution, used in tests only.
  MakeViewCommand({String? testRoot}) : _testRoot = testRoot;

  @override
  String get name => 'make:view';

  @override
  String get description => 'Create a new view class';

  @override
  String getDefaultNamespace() => 'lib/resources/views';

  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();

  @override
  void configure(ArgParser parser) {
    // 1. Register --force (and base args) from parent first.
    super.configure(parser);

    // 2. Add view-specific flags.
    parser.addFlag(
      'stateful',
      help: 'Generate a stateful view with lifecycle hooks',
      negatable: false,
    );
  }

  @override
  String getStub() => hasOption('stateful') ? viewStatefulStub : viewStub;

  /// Provides extra placeholder replacements for the view stub.
  ///
  /// [name] is the BASE name without the `View` suffix
  /// (e.g., `Login`, `Auth/Register`).
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

    // 1. Derive base name (no View suffix) and full name (with suffix).
    final baseName = _stripSuffix(rawName, 'View');
    final fullName = _withSuffix(rawName, 'View');

    // 2. Resolve output path using the FULL name so filename is correct
    //    (e.g., LoginView → login_view.dart).
    final filePath = getPath(fullName);

    // 3. Abort if file exists and --force was not provided.
    if (FileHelper.fileExists(filePath) && !hasOption('force')) {
      error('File already exists at $filePath');
      return;
    }

    // 4. Build stub content using the BASE name so {{ className }} resolves
    //    correctly — the stub appends "View" to the placeholder itself.
    final content = buildClass(baseName);
    FileHelper.writeFile(filePath, content);

    success('Created: $filePath');
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  /// Returns [name] with [suffix] appended to the last path segment if absent.
  ///
  /// Handles nested paths: `Auth/Register` → `Auth/RegisterView`.
  String _withSuffix(String name, String suffix) {
    final parts = name.split('/');
    final last = parts.last;
    final normalisedLast = last.endsWith(suffix) ? last : '$last$suffix';
    return [...parts.sublist(0, parts.length - 1), normalisedLast].join('/');
  }

  /// Returns [name] with [suffix] removed from the last path segment if present.
  ///
  /// Handles nested paths: `Auth/RegisterView` → `Auth/Register`.
  String _stripSuffix(String name, String suffix) {
    final parts = name.split('/');
    final last = parts.last;
    final strippedLast = last.endsWith(suffix)
        ? last.substring(0, last.length - suffix.length)
        : last;
    return [...parts.sublist(0, parts.length - 1), strippedLast].join('/');
  }
}
