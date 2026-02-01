import 'dart:io';
import 'package:yaml/yaml.dart';
import '../mcp_server.dart';

/// App Info MCP Tool.
///
/// Returns comprehensive application information including:
/// - App name and version from pubspec.yaml
/// - Flutter SDK version
/// - Magic framework dependencies
class AppInfoTool extends McpTool {
  @override
  String get description =>
      'Get application info: name, version, Flutter SDK, Magic dependencies. '
      'Use this on each new chat to understand the project context.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      return 'Error: pubspec.yaml not found in current directory';
    }

    final content = pubspec.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;

    final name = yaml['name'] ?? 'Unknown';
    final version = yaml['version'] ?? '0.0.0';
    final description = yaml['description'] ?? '';

    // Extract Flutter SDK constraint
    final environment = yaml['environment'] as YamlMap?;
    final flutterSdk = environment?['flutter'] ?? 'Not specified';
    final dartSdk = environment?['sdk'] ?? 'Not specified';

    // Find Magic dependencies
    final dependencies = yaml['dependencies'] as YamlMap? ?? YamlMap();
    final magicDeps = <String, String>{};

    for (final key in dependencies.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('fluttersdk_')) {
        final value = dependencies[key];
        if (value is String) {
          magicDeps[keyStr] = value;
        } else if (value is YamlMap && value['path'] != null) {
          magicDeps[keyStr] = 'path: ${value['path']}';
        } else {
          magicDeps[keyStr] = 'local';
        }
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('# Application Info');
    buffer.writeln();
    buffer.writeln('- **Name:** $name');
    buffer.writeln('- **Version:** $version');
    buffer.writeln('- **Description:** $description');
    buffer.writeln('- **Dart SDK:** $dartSdk');
    buffer.writeln('- **Flutter SDK:** $flutterSdk');
    buffer.writeln();
    buffer.writeln('## Magic Dependencies');
    if (magicDeps.isEmpty) {
      buffer.writeln('No Magic framework dependencies found.');
    } else {
      for (final entry in magicDeps.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }
}
