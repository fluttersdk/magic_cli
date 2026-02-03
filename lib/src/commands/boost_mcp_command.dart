import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';
import 'package:fluttersdk_magic_cli/src/mcp/mcp_server.dart';

/// The Boost MCP Command.
///
/// Runs the Magic Boost MCP server over stdio.
/// This server provides tools for AI assistants to understand the project.
///
/// Usage:
/// ```bash
/// magic boost:mcp
/// ```
class BoostMcpCommand extends Command {
  @override
  String get name => 'boost:mcp';

  @override
  String get description => 'Run the Magic Boost MCP server';

  @override
  void configure(ArgParser parser) {
    // No arguments needed for stdio server
  }

  @override
  Future<void> handle() async {
    final server = McpServer();
    await server.run();
  }
}
