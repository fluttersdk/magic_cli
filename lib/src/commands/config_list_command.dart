import 'dart:io';
import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/src/console/command.dart';

/// The Config List Command.
///
/// **PROTOTYPE**: This command uses static regex parsing and may not capture
/// all configuration patterns or dynamic values.
///
/// Parses config files in `lib/config/` directory and displays configuration
/// keys and their values.
///
/// Usage:
/// ```bash
/// dart run fluttersdk_magic_cli config:list
/// ```
class ConfigListCommand extends Command {
  @override
  String get name => 'config:list';

  @override
  String get description => 'List all configuration files and keys (prototype)';

  @override
  void configure(ArgParser parser) {
    parser.addFlag('verbose', abbr: 'v', help: 'Show configuration values');
  }

  @override
  Future<void> handle() async {
    final configDir = Directory('lib/config');

    if (!configDir.existsSync()) {
      error('Config directory not found: lib/config/');
      error('Make sure you are running this command from the project root.');
      return;
    }

    final configFiles = configDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    if (configFiles.isEmpty) {
      comment('No config files found in lib/config/');
      return;
    }

    final verbose = arguments['verbose'] as bool? ?? false;
    final allConfigs = <_ParsedConfig>[];

    for (final file in configFiles) {
      final configs = _parseConfigFile(file, verbose);
      allConfigs.addAll(configs);
    }

    if (allConfigs.isEmpty) {
      comment('No configuration entries found.');
      return;
    }

    // Print table
    _printTable(allConfigs, configFiles.length, verbose);
  }

  /// Parse a single config file and extract configuration entries.
  List<_ParsedConfig> _parseConfigFile(File file, bool verbose) {
    final content = file.readAsStringSync();
    final configs = <_ParsedConfig>[];
    final fileName = file.path.split('/').last.replaceAll('.dart', '');

    // Find the main config getter (e.g., Map<String, dynamic> get appConfig)
    final configPattern = RegExp(
      r"Map<String,\s*dynamic>\s+get\s+(\w+)\s*=>\s*\{",
      multiLine: true,
    );

    final configMatch = configPattern.firstMatch(content);
    if (configMatch == null) return configs;

    final configName = configMatch.group(1) ?? fileName;
    final startBrace = configMatch.end - 1;
    final endBrace = _findClosingBrace(content, startBrace + 1);
    final configBody = content.substring(startBrace, endBrace + 1);

    // Parse top-level keys
    final keyPattern = RegExp(r"'(\w+)':\s*\{", multiLine: true);
    for (final match in keyPattern.allMatches(configBody)) {
      final key = match.group(1)!;
      final keyStart = match.end - 1;
      final keyEnd = _findClosingBrace(configBody, keyStart + 1);
      final keyBody = configBody.substring(keyStart, keyEnd + 1);

      // Count nested keys
      final nestedKeys = _countNestedKeys(keyBody);

      configs.add(_ParsedConfig(
        file: fileName,
        configName: configName,
        key: key,
        nestedCount: nestedKeys,
        preview: verbose ? _extractPreview(keyBody) : '',
      ));
    }

    return configs;
  }

  /// Count nested keys in a config block.
  int _countNestedKeys(String body) {
    final keyPattern = RegExp(r"'(\w+)':");
    return keyPattern.allMatches(body).length;
  }

  /// Extract a preview of the config values.
  String _extractPreview(String body) {
    final lines = body.split('\n').where((l) => l.trim().isNotEmpty).take(3);
    return lines.map((l) => l.trim()).join(' ').substring(0, 50.clamp(0, 50));
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

  /// Print configs in a formatted table.
  void _printTable(List<_ParsedConfig> configs, int fileCount, bool verbose) {
    // Calculate column widths
    final fileWidth =
        configs.fold(4, (max, c) => c.file.length > max ? c.file.length : max);
    final keyWidth =
        configs.fold(3, (max, c) => c.key.length > max ? c.key.length : max);
    final countWidth = 6;

    void sep() {
      stdout.writeln(
          '+${'-' * (fileWidth + 2)}+${'-' * (keyWidth + 2)}+${'-' * (countWidth + 2)}+');
    }

    void row(String file, String key, String count) {
      stdout.writeln(
          '| ${file.padRight(fileWidth)} | ${key.padRight(keyWidth)} | ${count.padRight(countWidth)} |');
    }

    stdout.writeln('');
    sep();
    row('File', 'Key', 'Keys');
    sep();
    for (final c in configs) {
      row(c.file, c.key, c.nestedCount.toString());
    }
    sep();
    stdout.writeln('');
    info(
        '\x1B[32mFound ${configs.length} config section(s) in $fileCount file(s)\x1B[0m');
  }
}

/// Represents a parsed configuration entry.
class _ParsedConfig {
  final String file;
  final String configName;
  final String key;
  final int nestedCount;
  final String preview;

  _ParsedConfig({
    required this.file,
    required this.configName,
    required this.key,
    required this.nestedCount,
    required this.preview,
  });
}
