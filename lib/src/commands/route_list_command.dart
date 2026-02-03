import 'dart:io';
import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';

/// The Route List Command.
///
/// **PROTOTYPE**: This command uses static regex parsing and may not capture
/// all route patterns (e.g., dynamic routes, complex expressions).
///
/// Parses route files in `lib/routes/` directory and displays registered
/// routes in a formatted table.
///
/// Usage:
/// ```bash
/// dart run fluttersdk_magic_cli route:list
/// ```
class RouteListCommand extends Command {
  @override
  String get name => 'route:list';

  @override
  String get description => 'List all application routes (prototype)';

  @override
  void configure(ArgParser parser) {
    parser.addFlag('verbose', abbr: 'v', help: 'Show additional route details');
  }

  @override
  Future<void> handle() async {
    final routesDir = Directory('lib/routes');

    if (!routesDir.existsSync()) {
      error('Routes directory not found: lib/routes/');
      error('Make sure you are running this command from the project root.');
      return;
    }

    final routeFiles = routesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    if (routeFiles.isEmpty) {
      comment('No route files found in lib/routes/');
      return;
    }

    final allRoutes = <_ParsedRoute>[];

    for (final file in routeFiles) {
      final routes = _parseRouteFile(file);
      allRoutes.addAll(routes);
    }

    if (allRoutes.isEmpty) {
      comment('No routes found in route files.');
      return;
    }

    // Sort routes by path
    allRoutes.sort((a, b) => a.fullPath.compareTo(b.fullPath));

    // Print table
    _printTable(allRoutes, routeFiles.length);
  }

  /// Parse a single route file and extract route definitions.
  List<_ParsedRoute> _parseRouteFile(File file) {
    final content = file.readAsStringSync();
    final routes = <_ParsedRoute>[];

    // Parse MagicRoute.group() blocks - match entire group call
    final groupPattern = RegExp(
      r"MagicRoute\.group\s*\(([\s\S]*?)routes:\s*\(\)\s*\{",
      multiLine: true,
    );

    final groupMatches = groupPattern.allMatches(content);
    final groupRanges = <_GroupRange>[];

    for (final match in groupMatches) {
      final groupArgs = match.group(1) ?? '';

      // Extract prefix
      final prefixMatch = RegExp(r"prefix:\s*'([^']*)'").firstMatch(groupArgs);
      final prefix = prefixMatch?.group(1) ?? '';

      // Extract middleware
      final mwMatch =
          RegExp(r"middleware:\s*\[([^\]]*)\]").firstMatch(groupArgs);
      final middleware = _parseMiddlewareList(mwMatch?.group(1));

      final start = match.end;
      final end = _findClosingBrace(content, start);
      groupRanges.add(_GroupRange(
        prefix: prefix,
        middleware: middleware,
        start: start,
        end: end,
      ));
    }

    // Parse MagicRoute.page() calls
    final pagePattern = RegExp(
      r"MagicRoute\.page\s*\(\s*'([^']+)'",
      multiLine: true,
    );

    for (final match in pagePattern.allMatches(content)) {
      final path = match.group(1)!;
      final position = match.start;

      // Find which group this page belongs to
      String prefix = '';
      List<String> middleware = [];

      for (final group in groupRanges) {
        if (position > group.start && position < group.end) {
          prefix = group.prefix;
          middleware = group.middleware;
          break;
        }
      }

      // Check for inline middleware
      final endIdx = (match.end + 100).clamp(0, content.length);
      final afterMatch = content.substring(match.end, endIdx);
      final inlineMiddleware =
          RegExp(r"\.middleware\s*\(\s*\[([^\]]*)\]").firstMatch(afterMatch);
      if (inlineMiddleware != null) {
        middleware = [
          ...middleware,
          ..._parseMiddlewareList(inlineMiddleware.group(1))
        ];
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

  /// Parse middleware list from string like "'auth', 'admin'"
  List<String> _parseMiddlewareList(String? middlewareStr) {
    if (middlewareStr == null || middlewareStr.trim().isEmpty) return [];
    return RegExp(r"'([^']+)'")
        .allMatches(middlewareStr)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// Find the closing brace for a code block.
  int _findClosingBrace(String content, int startIndex) {
    int depth = 1;
    for (int i = startIndex; i < content.length; i++) {
      if (content[i] == '{') depth++;
      if (content[i] == '}') depth--;
      if (depth == 0) return i;
    }
    return content.length;
  }

  /// Print routes in a formatted table.
  void _printTable(List<_ParsedRoute> routes, int fileCount) {
    // Calculate column widths
    final pathWidth = routes.fold(
        4, (max, r) => r.fullPath.length > max ? r.fullPath.length : max);
    final mwWidth = routes.fold(
        10,
        (max, r) =>
            r.middlewareStr.length > max ? r.middlewareStr.length : max);
    final fileWidth = routes.fold(
        4, (max, r) => r.sourceFile.length > max ? r.sourceFile.length : max);

    void sep() {
      stdout.writeln(
          '+${'-' * (pathWidth + 2)}+${'-' * (mwWidth + 2)}+${'-' * (fileWidth + 2)}+');
    }

    void row(String path, String middleware, String file) {
      stdout.writeln(
          '| ${path.padRight(pathWidth)} | ${middleware.padRight(mwWidth)} | ${file.padRight(fileWidth)} |');
    }

    stdout.writeln('');
    sep();
    row('URI', 'Middleware', 'File');
    sep();
    for (final r in routes) {
      row(r.fullPath, r.middlewareStr, r.sourceFile);
    }
    sep();
    stdout.writeln('');
    info(
        '\x1B[32mShowing ${routes.length} route(s) from $fileCount file(s)\x1B[0m');
  }
}

/// Represents a parsed route definition.
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

/// Represents a group block range in the source file.
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
