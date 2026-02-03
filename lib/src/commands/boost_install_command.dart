import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';
import 'package:fluttersdk_magic_cli/src/boost/guideline_generator.dart';

/// The Boost Install Command.
///
/// Sets up Magic Boost for AI-assisted development:
/// - Creates `.magic/guidelines/` with framework documentation
/// - Detects IDE (Cursor/VS Code) and registers MCP server
///
/// Usage:
/// ```bash
/// magic boost:install
/// ```
class BoostInstallCommand extends Command {
  @override
  String get name => 'boost:install';

  @override
  String get description => 'Install Magic Boost for AI-assisted development';

  @override
  void configure(ArgParser parser) {
    parser.addFlag('ignore-guidelines', help: 'Skip installing AI guidelines');
    parser.addFlag('ignore-mcp', help: 'Skip installing MCP server config');
  }

  @override
  Future<void> handle() async {
    final ignoreGuidelines = arguments['ignore-guidelines'] as bool? ?? false;
    final ignoreMcp = arguments['ignore-mcp'] as bool? ?? false;

    if (ignoreGuidelines && ignoreMcp) {
      error('Cannot ignore both guidelines and MCP. Select at least one.');
      return;
    }

    _displayHeader();

    // Install guidelines
    if (!ignoreGuidelines) {
      await _installGuidelines();
    }

    // Install MCP config
    if (!ignoreMcp) {
      await _installMcpConfig();
    }

    _displayOutro();
  }

  void _displayHeader() {
    info('');
    info('\x1B[36m'
        r'''
    ███╗   ███╗ █████╗  ██████╗ ██╗ ██████╗
    ████╗ ████║██╔══██╗██╔════╝ ██║██╔════╝
    ██╔████╔██║███████║██║  ███╗██║██║
    ██║╚██╔╝██║██╔══██║██║   ██║██║██║
    ██║ ╚═╝ ██║██║  ██║╚██████╔╝██║╚██████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═════╝
    '''
        '\x1B[0m');
    info('\x1B[1m✦ Magic Boost :: Install ✦\x1B[0m');
    info('');
  }

  Future<void> _installGuidelines() async {
    info('📚 Installing AI guidelines...');

    final generator = GuidelineGenerator(Directory.current.path);
    await generator.generate();

    info('  \x1B[32m✓\x1B[0m Created .magic/guidelines/core.md');
    info('  \x1B[32m✓\x1B[0m Created .magic/guidelines/wind.md');
    info('  \x1B[32m✓\x1B[0m Created .magic/guidelines/eloquent.md');
    info('  \x1B[32m✓\x1B[0m Created .magic/guidelines/routing.md');
    info('');
  }

  Future<void> _installMcpConfig() async {
    info('🔌 Installing MCP server configuration...');

    final detectedIdes = _detectIdes();

    if (detectedIdes.isEmpty) {
      comment('  No supported IDEs detected (Cursor, VS Code)');
      comment('  You can manually configure MCP later.');
      return;
    }

    for (final ide in detectedIdes) {
      final success = await _configureMcp(ide);
      if (success) {
        if (ide.isNew) {
          info('  \x1B[32m✓\x1B[0m Created ${ide.configPath}');
        } else {
          info('  \x1B[32m✓\x1B[0m Updated ${ide.name}');
        }
      } else {
        error('  \x1B[31m✗\x1B[0m Failed to configure ${ide.name}');
      }
    }
    info('');
  }

  List<_IdeConfig> _detectIdes() {
    final ides = <_IdeConfig>[];
    final home = Platform.environment['HOME'] ?? '';

    // Cursor IDE - check both global and project config
    final cursorGlobal = File('$home/.cursor/mcp.json');
    final cursorProject = File('.cursor/mcp.json');

    // Prefer project-level config, then global
    if (cursorProject.existsSync()) {
      ides.add(_IdeConfig(
        name: 'Cursor (project)',
        configPath: cursorProject.path,
        isProject: true,
        isNew: false,
      ));
    } else if (cursorGlobal.existsSync()) {
      ides.add(_IdeConfig(
        name: 'Cursor (global)',
        configPath: cursorGlobal.path,
        isProject: false,
        isNew: false,
      ));
    } else {
      // Create project-level config for Cursor
      ides.add(_IdeConfig(
        name: 'Cursor',
        configPath: '.cursor/mcp.json',
        isProject: true,
        isNew: true,
      ));
    }

    // VS Code MCP config (project level)
    final vscodeConfig = File('.vscode/mcp.json');
    ides.add(_IdeConfig(
      name: 'VS Code',
      configPath: vscodeConfig.path,
      isProject: true,
      isNew: !vscodeConfig.existsSync(),
    ));

    return ides;
  }

  Future<bool> _configureMcp(_IdeConfig ide) async {
    try {
      final file = File(ide.configPath);
      Map<String, dynamic> config = {};

      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content);
          config = Map<String, dynamic>.from(decoded as Map);
        }
      } else {
        // Create parent directory if needed
        final parent = file.parent;
        if (!parent.existsSync()) {
          parent.createSync(recursive: true);
        }
      }

      // Get the path to magic CLI - use the script path
      final scriptUri = Platform.script;
      String magicCliPath;

      if (scriptUri.scheme == 'file') {
        magicCliPath = scriptUri.toFilePath();
      } else {
        // Fallback for pub global activate
        magicCliPath = 'fluttersdk_magic_cli:magic';
      }

      final projectPath = Directory.current.path;

      // Get or create mcpServers map
      final mcpServers = config['mcpServers'] as Map? ?? {};
      final newMcpServers = Map<String, dynamic>.from(mcpServers);

      // Add magic-boost server
      newMcpServers['magic-boost'] = {
        'command': 'dart',
        'args': ['run', magicCliPath, 'boost:mcp'],
        'cwd': projectPath,
      };

      config['mcpServers'] = newMcpServers;

      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(config),
      );

      return true;
    } catch (e) {
      comment('    Error: $e');
      return false;
    }
  }

  void _displayOutro() {
    info('\x1B[32m🚀 Magic Boost installed successfully!\x1B[0m');
    info('');
    info('Next steps:');
    info('  1. Restart your IDE to activate MCP');
    info('  2. Start chatting with your AI assistant');
    info('');
  }
}

class _IdeConfig {
  final String name;
  final String configPath;
  final bool isProject;
  final bool isNew;

  _IdeConfig({
    required this.name,
    required this.configPath,
    required this.isProject,
    required this.isNew,
  });
}
