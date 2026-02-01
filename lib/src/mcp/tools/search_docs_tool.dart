import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import '../mcp_server.dart';

/// Search Docs MCP Tool.
///
/// Searches official Magic documentation at magic.fluttersdk.com.
/// Automatically includes package versions from pubspec.lock.
class SearchDocsTool extends McpTool {
  // static const _apiUrl = 'https://magic.fluttersdk.com/api/docs/search';
  static const _apiUrl = 'http://localhost:3535/api/docs/search';

  @override
  String get description =>
      'Search Magic framework documentation. Results are version-specific '
      'based on installed packages. Use for API reference, guides, and examples.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'queries': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Search queries (e.g., ["routing", "middleware"])',
          },
          'packages': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Limit search to specific packages',
          },
          'token_limit': {
            'type': 'integer',
            'description': 'Max tokens in response (default: 3000)',
          },
        },
        'required': ['queries'],
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final queries = (arguments['queries'] as List?)?.cast<String>() ?? [];
    final packagesFilter = (arguments['packages'] as List?)?.cast<String>();
    final tokenLimit = arguments['token_limit'] as int? ?? 3000;

    if (queries.isEmpty) {
      return 'Error: No search queries provided.';
    }

    // Get installed packages
    final packages = _getInstalledPackages(packagesFilter);

    final payload = {
      'queries': queries,
      'packages': packages,
      'token_limit': tokenLimit.clamp(100, 100000),
      'format': 'markdown',
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        print(response.body);
        print(response.statusCode);
        print(response.request?.url);

        return 'Error: Documentation API returned ${response.statusCode}\n${response.body}';
      }

      return response.body;
    } catch (e) {
      return 'Error: Failed to search documentation: $e';
    }
  }

  List<Map<String, String>> _getInstalledPackages(List<String>? filter) {
    final packages = <Map<String, String>>[];

    // Try pubspec.lock first
    final lockFile = File('pubspec.lock');
    if (lockFile.existsSync()) {
      try {
        final content = lockFile.readAsStringSync();
        final yaml = loadYaml(content) as YamlMap;
        final packageMap = yaml['packages'] as YamlMap? ?? YamlMap();

        for (final entry in packageMap.entries) {
          final name = entry.key.toString();
          final data = entry.value as YamlMap;
          final version = data['version']?.toString() ?? '';

          if (name.startsWith('fluttersdk_')) {
            if (filter == null || filter.contains(name)) {
              packages.add({
                'name': name,
                'version': _extractMajorVersion(version),
              });
            }
          }
        }
      } catch (_) {}
    }

    // Fallback to pubspec.yaml
    if (packages.isEmpty) {
      final pubspec = File('pubspec.yaml');
      if (pubspec.existsSync()) {
        try {
          final content = pubspec.readAsStringSync();
          final yaml = loadYaml(content) as YamlMap;
          final deps = yaml['dependencies'] as YamlMap? ?? YamlMap();

          for (final key in deps.keys) {
            final name = key.toString();
            if (name.startsWith('fluttersdk_')) {
              if (filter == null || filter.contains(name)) {
                packages.add({'name': name, 'version': 'latest'});
              }
            }
          }
        } catch (_) {}
      }
    }

    // Always include core Magic packages
    if (packages.isEmpty) {
      packages.add({'name': 'fluttersdk_magic', 'version': 'latest'});
      packages.add({'name': 'fluttersdk_wind', 'version': 'latest'});
    }

    return packages;
  }

  String _extractMajorVersion(String version) {
    final parts = version.split('.');
    if (parts.isNotEmpty) {
      return '${parts.first}.x';
    }
    return 'latest';
  }
}
