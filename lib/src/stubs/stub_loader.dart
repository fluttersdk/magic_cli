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
  /// Searches for `{name}.stub` in the provided search paths.
  /// If no search paths provided, uses default CLI stubs directory.
  /// Returns the raw stub content as a string.
  static Future<String> load(String name, {List<String>? searchPaths}) async {
    final stubPath = _findStubPath(name, searchPaths);
    final file = File(stubPath);

    if (!file.existsSync()) {
      throw StubNotFoundException(name);
    }

    return file.readAsStringSync();
  }

  /// Load a stub file synchronously.
  static String loadSync(String name, {List<String>? searchPaths}) {
    final stubPath = _findStubPath(name, searchPaths);
    final file = File(stubPath);

    if (!file.existsSync()) {
      throw StubNotFoundException(name);
    }

    return file.readAsStringSync();
  }

  /// Find the path to a stub file by searching multiple directories.
  ///
  /// Searches in order:
  /// 1. Provided search paths
  /// 2. Default CLI package stubs directory
  static String _findStubPath(String name, List<String>? searchPaths) {
    final paths = searchPaths ?? [];

    // Add default path as fallback
    paths.add(_getDefaultStubPath());

    for (final searchPath in paths) {
      final stubPath = path.join(searchPath, '$name.stub');
      if (File(stubPath).existsSync()) {
        return stubPath;
      }
    }

    // Return the default path even if not found (for error message)
    return path.join(_getDefaultStubPath(), '$name.stub');
  }

  /// Get the default stub path.
  ///
  /// Resolves the path relative to the CLI package location.
  static String _getDefaultStubPath() {
    // Get the directory where this script is running from
    final scriptPath = Platform.script.toFilePath();
    final scriptDir = path.dirname(scriptPath);

    // Go up to the package root and find assets/stubs
    final packageRoot = path.dirname(scriptDir); // bin -> package root
    return path.join(packageRoot, 'assets', 'stubs');
  }

  /// Check if a stub file exists.
  static bool exists(String name, {List<String>? searchPaths}) {
    try {
      final stubPath = _findStubPath(name, searchPaths);
      return File(stubPath).existsSync();
    } catch (e) {
      return false;
    }
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
    String name,
    Map<String, String> replacements, {
    List<String>? searchPaths,
  }) async {
    final stub = await load(name, searchPaths: searchPaths);
    return replace(stub, replacements);
  }

  /// Load and replace synchronously.
  static String makeSync(
    String name,
    Map<String, String> replacements, {
    List<String>? searchPaths,
  }) {
    final stub = loadSync(name, searchPaths: searchPaths);
    return replace(stub, replacements);
  }

  // Case transformation utilities

  /// Convert snake_case to PascalCase.
  ///
  /// Example: 'user_profile' -> 'UserProfile'
  static String toPascalCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join('');
  }

  /// Convert PascalCase to snake_case.
  ///
  /// Example: 'UserProfile' -> 'user_profile'
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  /// Convert PascalCase to kebab-case.
  ///
  /// Example: 'UserProfile' -> 'user-profile'
  static String toKebabCase(String input) {
    return toSnakeCase(input).replaceAll('_', '-');
  }

  /// Convert snake_case to camelCase.
  ///
  /// Example: 'user_profile' -> 'userProfile'
  static String toCamelCase(String input) {
    if (input.isEmpty) return input;
    final parts = input.split('_');
    if (parts.isEmpty) return input;

    final buffer = StringBuffer(parts[0]);
    for (var i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        buffer.write(parts[i][0].toUpperCase());
        if (parts[i].length > 1) {
          buffer.write(parts[i].substring(1));
        }
      }
    }
    return buffer.toString();
  }
}

/// Exception thrown when a stub file is not found.
class StubNotFoundException implements Exception {
  final String stubName;

  StubNotFoundException(this.stubName);

  @override
  String toString() => 'Stub not found: $stubName.stub';
}
