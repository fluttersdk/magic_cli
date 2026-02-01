import 'dart:io';
import '../mcp_server.dart';

/// List Routes MCP Tool.
///
/// Parses route files in `lib/routes/` and returns all registered routes
/// with their paths, middleware, and source files.
class ListRoutesTool extends McpTool {
  @override
  String get description =>
      'List all application routes with paths, middleware, and handlers. '
      'Useful for understanding application structure and navigation.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'method': {
            'type': 'string',
            'description': 'Filter by HTTP method (GET, POST, etc.)',
          },
          'path': {
            'type': 'string',
            'description': 'Filter by path pattern',
          },
        },
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final routesDir = Directory('lib/routes');
    if (!routesDir.existsSync()) {
      return 'Error: lib/routes/ directory not found';
    }

    final routeFiles = routesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    if (routeFiles.isEmpty) {
      return 'No route files found in lib/routes/';
    }

    final allRoutes = <_ParsedRoute>[];
    for (final file in routeFiles) {
      allRoutes.addAll(_parseRouteFile(file));
    }

    final pathFilter = arguments['path'] as String?;
    var filtered = allRoutes;
    if (pathFilter != null && pathFilter.isNotEmpty) {
      filtered =
          allRoutes.where((r) => r.fullPath.contains(pathFilter)).toList();
    }

    filtered.sort((a, b) => a.fullPath.compareTo(b.fullPath));

    final buffer = StringBuffer();
    buffer.writeln('# Application Routes');
    buffer.writeln();
    buffer.writeln('| URI | Middleware | File |');
    buffer.writeln('|-----|------------|------|');
    for (final route in filtered) {
      buffer.writeln(
          '| ${route.fullPath} | ${route.middlewareStr} | ${route.sourceFile} |');
    }
    buffer.writeln();
    buffer.writeln(
        'Total: ${filtered.length} routes from ${routeFiles.length} files');

    return buffer.toString();
  }

  List<_ParsedRoute> _parseRouteFile(File file) {
    final content = file.readAsStringSync();
    final routes = <_ParsedRoute>[];

    // Parse MagicRoute.group() blocks
    final groupPattern = RegExp(
      r"MagicRoute\.group\s*\(([\s\S]*?)routes:\s*\(\)\s*\{",
      multiLine: true,
    );

    final groupRanges = <_GroupRange>[];
    for (final match in groupPattern.allMatches(content)) {
      final groupArgs = match.group(1) ?? '';
      final prefixMatch = RegExp(r"prefix:\s*'([^']*)'").firstMatch(groupArgs);
      final mwMatch =
          RegExp(r"middleware:\s*\[([^\]]*)\]").firstMatch(groupArgs);

      groupRanges.add(_GroupRange(
        prefix: prefixMatch?.group(1) ?? '',
        middleware: _parseMiddlewareList(mwMatch?.group(1)),
        start: match.end,
        end: _findClosingBrace(content, match.end),
      ));
    }

    // Parse MagicRoute.page() calls
    final pagePattern =
        RegExp(r"MagicRoute\.page\s*\(\s*'([^']+)'", multiLine: true);
    for (final match in pagePattern.allMatches(content)) {
      final path = match.group(1)!;
      final position = match.start;

      String prefix = '';
      List<String> middleware = [];
      for (final group in groupRanges) {
        if (position > group.start && position < group.end) {
          prefix = group.prefix;
          middleware = group.middleware;
          break;
        }
      }

      routes.add(_ParsedRoute(
        path: path,
        prefix: prefix,
        middleware: middleware,
        sourceFile: file.path.split('/').last,
      ));
    }

    return routes;
  }

  List<String> _parseMiddlewareList(String? str) {
    if (str == null || str.trim().isEmpty) return [];
    return RegExp(r"'([^']+)'")
        .allMatches(str)
        .map((m) => m.group(1)!)
        .toList();
  }

  int _findClosingBrace(String content, int start) {
    int depth = 1;
    for (int i = start; i < content.length; i++) {
      if (content[i] == '{') depth++;
      if (content[i] == '}') depth--;
      if (depth == 0) return i;
    }
    return content.length;
  }
}

class _ParsedRoute {
  final String path;
  final String prefix;
  final List<String> middleware;
  final String sourceFile;

  _ParsedRoute({
    required this.path,
    required this.prefix,
    required this.middleware,
    required this.sourceFile,
  });

  String get fullPath {
    if (prefix.isEmpty) return path;
    if (path == '/') return prefix;
    return '$prefix$path';
  }

  String get middlewareStr => middleware.isEmpty ? '-' : middleware.join(', ');
}

class _GroupRange {
  final String prefix;
  final List<String> middleware;
  final int start;
  final int end;

  _GroupRange({
    required this.prefix,
    required this.middleware,
    required this.start,
    required this.end,
  });
}
