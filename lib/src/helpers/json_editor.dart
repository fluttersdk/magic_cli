import 'dart:convert';
import 'dart:io';

/// JSON file manipulation helper for CLI commands.
///
/// Provides utilities for reading, writing, and merging JSON files using only
/// Dart's built-in `dart:convert` library — no external packages required.
///
/// ## Usage
///
/// ```dart
/// // Read a JSON file
/// final data = JsonEditor.readJson('/path/to/manifest.json');
///
/// // Merge a single key (idempotent overwrite)
/// JsonEditor.mergeKey('/path/to/manifest.json', 'gcm_sender_id', '482941778795');
///
/// // Write a full map
/// JsonEditor.writeJson('/path/to/output.json', {'key': 'value'});
///
/// // Check if a key exists
/// if (!JsonEditor.hasKey('/path/to/manifest.json', 'gcm_sender_id')) {
///   JsonEditor.mergeKey(...);
/// }
/// ```
class JsonEditor {
  JsonEditor._();

  // -------------------------------------------------------------------------
  // Read
  // -------------------------------------------------------------------------

  /// Read and parse a JSON file from [path].
  ///
  /// @param path  Absolute or relative path to the `.json` file.
  /// @return A [Map<String, dynamic>] of the decoded JSON object.
  ///
  /// @throws [FileSystemException] if the file does not exist.
  /// @throws [FormatException]     if the file contains invalid JSON.
  static Map<String, dynamic> readJson(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('JSON file not found', path);
    }

    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  // -------------------------------------------------------------------------
  // Write
  // -------------------------------------------------------------------------

  /// Serialise [data] and write it to [path] as pretty-printed JSON.
  ///
  /// Creates parent directories and the file if they do not exist.
  /// Overwrites any existing content.
  ///
  /// @param path    Destination file path.
  /// @param data    The object to serialise (typically `Map<String, dynamic>`).
  /// @param indent  Number of spaces for indentation (default: `2`).
  static void writeJson(
    String path,
    dynamic data, {
    int indent = 2,
  }) {
    final file = File(path);

    // 1. Ensure parent directory exists.
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    // 2. Encode and write with the requested indentation.
    final encoder = JsonEncoder.withIndent(' ' * indent);
    file.writeAsStringSync(encoder.convert(data));
  }

  // -------------------------------------------------------------------------
  // Merge
  // -------------------------------------------------------------------------

  /// Read the JSON file at [path], set [key] to [value], and write it back.
  ///
  /// All existing keys are preserved. If [key] already exists its value is
  /// overwritten.
  ///
  /// @param path   Path to the `.json` file.
  /// @param key    Top-level key to insert or update.
  /// @param value  The new value for [key].
  ///
  /// @throws [FileSystemException] if the file does not exist.
  /// @throws [FormatException]     if the file contains invalid JSON.
  static void mergeKey(String path, String key, dynamic value) {
    // 1. Load current state.
    final data = readJson(path);

    // 2. Apply the change.
    data[key] = value;

    // 3. Persist.
    writeJson(path, data);
  }

  // -------------------------------------------------------------------------
  // Inspection
  // -------------------------------------------------------------------------

  /// Check whether [key] exists as a top-level key in the JSON file.
  ///
  /// Returns `false` (instead of throwing) when the file does not exist or
  /// cannot be parsed — making this safe to use as a precondition guard.
  ///
  /// @param path  Path to the `.json` file.
  /// @param key   Top-level key to look for.
  /// @return `true` if the key is present, `false` in all other cases.
  static bool hasKey(String path, String key) {
    try {
      final data = readJson(path);
      return data.containsKey(key);
    } catch (_) {
      return false;
    }
  }
}
