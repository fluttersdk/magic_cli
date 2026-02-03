import 'dart:io';
import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';

/// The Config Get Command.
///
/// **PROTOTYPE**: Uses static regex parsing to extract configuration values.
///
/// Resolves config values with priority:
/// 1. Project config (lib/config/*.dart)
/// 2. Environment variables (.env)
/// 3. Framework defaults
///
/// Usage:
/// ```bash
/// dart run fluttersdk_magic_cli config:get app.name
/// dart run fluttersdk_magic_cli config:get network.default
/// ```
class ConfigGetCommand extends Command {
  @override
  String get name => 'config:get';

  @override
  String get description => 'Get a configuration value (prototype)';

  @override
  void configure(ArgParser parser) {
    parser.addFlag('show-source',
        abbr: 's', help: 'Show where value came from');
  }

  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a config key, e.g.: config:get app.name');
      return;
    }

    final key = arguments.rest.first;
    final showSource = arguments['show-source'] as bool? ?? false;

    final result = _resolveValue(key);

    if (result == null) {
      error('Config key "$key" not found.');
      return;
    }

    if (showSource) {
      info('${result.value} \x1B[90m(from ${result.source})\x1B[0m');
    } else {
      info(result.value);
    }
  }

  /// Resolve a config value with priority lookup.
  _ConfigResult? _resolveValue(String key) {
    final parts = key.split('.');
    if (parts.isEmpty) return null;

    final rootKey = parts.first;
    final nestedPath = parts.sublist(1);

    // 1. Try project config first
    final projectValue = _lookupProjectConfig(rootKey, nestedPath);
    if (projectValue != null) {
      // Check if it's an env() reference
      final envMatch =
          RegExp(r"env\s*\(\s*'([^']+)'(?:\s*,\s*'?([^')]*)'?)?\s*\)")
              .firstMatch(projectValue);
      if (envMatch != null) {
        final envKey = envMatch.group(1)!;
        final defaultValue = envMatch.group(2);

        // 2. Try .env file
        final envValue = _lookupEnv(envKey);
        if (envValue != null) {
          return _ConfigResult(envValue, '.env ($envKey)');
        }

        // Return default from env() call
        if (defaultValue != null && defaultValue.isNotEmpty) {
          return _ConfigResult(defaultValue, 'project config (default)');
        }
      } else {
        return _ConfigResult(projectValue, 'project config');
      }
    }

    // 3. Try framework defaults
    final frameworkValue = _lookupFrameworkDefaults(rootKey, nestedPath);
    if (frameworkValue != null) {
      return _ConfigResult(frameworkValue, 'framework defaults');
    }

    return null;
  }

  /// Lookup value in project config files.
  String? _lookupProjectConfig(String rootKey, List<String> nestedPath) {
    final configDir = Directory('lib/config');
    if (!configDir.existsSync()) return null;

    for (final file in configDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;

      final content = file.readAsStringSync();
      final value = _extractValue(content, rootKey, nestedPath);
      if (value != null) return value;
    }
    return null;
  }

  /// Lookup value in .env file.
  String? _lookupEnv(String key) {
    final envFile = File('.env');
    if (!envFile.existsSync()) return null;

    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;

      final idx = trimmed.indexOf('=');
      final envKey = trimmed.substring(0, idx).trim();
      final envValue = trimmed.substring(idx + 1).trim();

      if (envKey == key) {
        return envValue;
      }
    }
    return null;
  }

  /// Lookup value in framework defaults.
  String? _lookupFrameworkDefaults(String rootKey, List<String> nestedPath) {
    // Framework defaults location (relative to CLI execution)
    final frameworkConfigDir = Directory('plugins/fluttersdk_magic/lib/config');
    if (!frameworkConfigDir.existsSync()) return null;

    for (final file in frameworkConfigDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;

      final content = file.readAsStringSync();
      final value = _extractValue(content, rootKey, nestedPath);
      if (value != null) return value;
    }
    return null;
  }

  /// Extract a value from config content using the key path.
  String? _extractValue(
      String content, String rootKey, List<String> nestedPath) {
    // Find the root key block
    final rootPattern = RegExp(
      "'$rootKey':\\s*\\{",
      multiLine: true,
    );

    final rootMatch = rootPattern.firstMatch(content);
    if (rootMatch == null) return null;

    String currentContent = content.substring(rootMatch.end - 1);

    // Navigate through nested path
    for (final key in nestedPath) {
      final nestedPattern = RegExp("'$key':\\s*");
      final nestedMatch = nestedPattern.firstMatch(currentContent);
      if (nestedMatch == null) return null;

      currentContent = currentContent.substring(nestedMatch.end);
    }

    // Extract the value
    // Handle different value types
    final valuePatterns = [
      RegExp(r"^'([^']*)'"), // String value
      RegExp(r'^"([^"]*)"'), // Double-quoted string
      RegExp(r'^(\d+)'), // Number
      RegExp(r'^(true|false)'), // Boolean
      RegExp(r'^(null)'), // Null
      RegExp(r"^(env\s*\([^)]+\))"), // env() call
    ];

    for (final pattern in valuePatterns) {
      final match = pattern.firstMatch(currentContent.trim());
      if (match != null) {
        return match.group(1) ?? match.group(0);
      }
    }

    return null;
  }
}

/// Represents a resolved config value with its source.
class _ConfigResult {
  final String value;
  final String source;

  _ConfigResult(this.value, this.source);
}
