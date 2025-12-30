import 'dart:io';

import 'package:path/path.dart' as path;

/// Utility class to load and process `.stub` template files.
///
/// Stubs use `{{ placeholder }}` syntax for replacements, similar to Laravel.
///
/// ## Usage
///
/// ```dart
/// final stub = await StubLoader.load('migration');
/// final content = StubLoader.replace(stub, {
///   'className': 'CreateUsersTable',
///   'fullName': '2024_01_15_create_users_table',
/// });
/// ```
class StubLoader {
  /// Load a stub file by name.
  ///
  /// Searches for `{name}.stub` in the assets/stubs directory.
  /// Returns the raw stub content as a string.
  static Future<String> load(String name) async {
    final stubPath = _getStubPath(name);
    final file = File(stubPath);

    if (!file.existsSync()) {
      throw StubNotFoundException(name);
    }

    return file.readAsStringSync();
  }

  /// Load a stub file synchronously.
  static String loadSync(String name) {
    final stubPath = _getStubPath(name);
    final file = File(stubPath);

    if (!file.existsSync()) {
      throw StubNotFoundException(name);
    }

    return file.readAsStringSync();
  }

  /// Get the path to a stub file.
  ///
  /// Resolves the path relative to the CLI package location.
  static String _getStubPath(String name) {
    // Get the directory where this script is running from
    final scriptPath = Platform.script.toFilePath();
    final scriptDir = path.dirname(scriptPath);

    // Go up to the package root and find assets/stubs
    final packageRoot = path.dirname(scriptDir); // bin -> package root
    return path.join(packageRoot, 'assets', 'stubs', '$name.stub');
  }

  /// Check if a stub file exists.
  static bool exists(String name) {
    return File(_getStubPath(name)).existsSync();
  }

  /// Replace placeholders in a stub with provided values.
  ///
  /// Placeholders use `{{ key }}` syntax (with or without spaces).
  /// All occurrences of each key are replaced.
  static String replace(String stub, Map<String, String> replacements) {
    var result = stub;

    for (final entry in replacements.entries) {
      // Match {{ key }} with flexible whitespace
      final pattern = RegExp(r'\{\{\s*' + entry.key + r'\s*\}\}');
      result = result.replaceAll(pattern, entry.value);
    }

    return result;
  }

  /// Load and replace in one step.
  static Future<String> make(
      String name, Map<String, String> replacements) async {
    final stub = await load(name);
    return replace(stub, replacements);
  }

  /// Load and replace synchronously.
  static String makeSync(String name, Map<String, String> replacements) {
    final stub = loadSync(name);
    return replace(stub, replacements);
  }
}

/// Exception thrown when a stub file is not found.
class StubNotFoundException implements Exception {
  final String stubName;

  StubNotFoundException(this.stubName);

  @override
  String toString() => 'Stub not found: $stubName.stub';
}
