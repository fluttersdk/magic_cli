import 'dart:io';
import '../mcp_server.dart';

/// Get Config MCP Tool.
///
/// Reads configuration values from:
/// 1. Project config files (lib/config/*.dart)
/// 2. Environment variables (.env)
class GetConfigTool extends McpTool {
  @override
  String get description =>
      'Get configuration values from project config files and .env. '
      'Use dot notation like "app.name" or "network.default".';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'key': {
            'type': 'string',
            'description': 'Config key in dot notation (e.g., app.name)',
          },
        },
        'required': ['key'],
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final key = arguments['key'] as String?;
    if (key == null || key.isEmpty) {
      return _listAllConfigs();
    }

    final result = _resolveValue(key);
    if (result == null) {
      return 'Config key "$key" not found.';
    }

    return '**$key**: ${result.value} (from ${result.source})';
  }

  String _listAllConfigs() {
    final buffer = StringBuffer();
    buffer.writeln('# Configuration Overview');
    buffer.writeln();

    // List .env
    final envFile = File('.env');
    if (envFile.existsSync()) {
      buffer.writeln('## Environment Variables (.env)');
      buffer.writeln();
      for (final line in envFile.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          buffer.writeln('- $trimmed');
        }
      }
      buffer.writeln();
    }

    // List config files
    final configDir = Directory('lib/config');
    if (configDir.existsSync()) {
      buffer.writeln('## Config Files');
      buffer.writeln();
      for (final file in configDir.listSync().whereType<File>()) {
        if (file.path.endsWith('.dart')) {
          buffer.writeln('- ${file.path.split('/').last}');
        }
      }
    }

    return buffer.toString();
  }

  _ConfigResult? _resolveValue(String key) {
    final parts = key.split('.');
    if (parts.isEmpty) return null;

    final rootKey = parts.first;
    final nestedPath = parts.sublist(1);

    // Try project config
    final configDir = Directory('lib/config');
    if (configDir.existsSync()) {
      for (final file in configDir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();
        final value = _extractValue(content, rootKey, nestedPath);
        if (value != null) {
          // Check for env() reference
          final envMatch =
              RegExp(r"env\s*\(\s*'([^']+)'(?:\s*,\s*'?([^')]*)'?)?\s*\)")
                  .firstMatch(value);
          if (envMatch != null) {
            final envKey = envMatch.group(1)!;
            final defaultVal = envMatch.group(2);
            final envValue = _lookupEnv(envKey);
            if (envValue != null) {
              return _ConfigResult(envValue, '.env ($envKey)');
            }
            if (defaultVal != null && defaultVal.isNotEmpty) {
              return _ConfigResult(defaultVal, 'config default');
            }
          } else {
            return _ConfigResult(value, 'project config');
          }
        }
      }
    }

    return null;
  }

  String? _lookupEnv(String key) {
    final envFile = File('.env');
    if (!envFile.existsSync()) return null;

    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;
      final idx = trimmed.indexOf('=');
      if (trimmed.substring(0, idx).trim() == key) {
        return trimmed.substring(idx + 1).trim();
      }
    }
    return null;
  }

  String? _extractValue(
      String content, String rootKey, List<String> nestedPath) {
    final rootPattern = RegExp("'$rootKey':\\s*\\{", multiLine: true);
    final rootMatch = rootPattern.firstMatch(content);
    if (rootMatch == null) return null;

    var currentContent = content.substring(rootMatch.end - 1);

    for (final key in nestedPath) {
      final nestedPattern = RegExp("'$key':\\s*");
      final nestedMatch = nestedPattern.firstMatch(currentContent);
      if (nestedMatch == null) return null;
      currentContent = currentContent.substring(nestedMatch.end);
    }

    final valuePatterns = [
      RegExp(r"^'([^']*)'"),
      RegExp(r'^"([^"]*)"'),
      RegExp(r'^(\d+)'),
      RegExp(r'^(true|false)'),
      RegExp(r'^(null)'),
      RegExp(r"^(env\s*\([^)]+\))"),
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

class _ConfigResult {
  final String value;
  final String source;

  _ConfigResult(this.value, this.source);
}
