import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';

import 'tools/app_info_tool.dart';
import 'tools/get_config_tool.dart';
import 'tools/list_routes_tool.dart';
import 'tools/search_docs_tool.dart';
import 'tools/validate_wind_tool.dart';

/// Magic Boost MCP Server.
///
/// Implements MCP (Model Context Protocol) over stdio using JSON-RPC 2.0.
/// Provides tools for AI assistants to understand the project structure.
class McpServer {
  late final Peer _peer;
  final Map<String, McpTool> _tools = {};

  McpServer() {
    _registerTools();
  }

  void _registerTools() {
    _tools['app_info'] = AppInfoTool();
    _tools['list_routes'] = ListRoutesTool();
    _tools['get_config'] = GetConfigTool();
    _tools['validate_wind'] = ValidateWindTool();
    _tools['search_docs'] = SearchDocsTool();
  }

  /// Run the MCP server over stdio.
  Future<void> run() async {
    final channel = _createStdioChannel();
    _peer = Peer(channel);

    // Register MCP methods
    _peer.registerMethod('initialize', _handleInitialize);
    _peer.registerMethod('tools/list', _handleToolsList);
    _peer.registerMethod('tools/call', _handleToolsCall);

    await _peer.listen();
  }

  StreamChannel<String> _createStdioChannel() {
    final input = stdin.transform(utf8.decoder).transform(const LineSplitter());
    final output = StreamController<String>();
    output.stream.listen((data) {
      stdout.writeln(data);
    });
    return StreamChannel(input, output.sink);
  }

  /// Handle MCP initialize request.
  Map<String, dynamic> _handleInitialize(Parameters params) {
    return {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'tools': {'listChanged': false},
      },
      'serverInfo': {
        'name': 'Magic Boost',
        'version': '0.0.1',
      },
      'instructions': 'Magic Boost MCP server for Flutter/Dart projects. '
          'Provides tools for project introspection, route listing, '
          'config access, Wind UI validation, and documentation search.',
    };
  }

  /// Handle tools/list request.
  Map<String, dynamic> _handleToolsList(Parameters params) {
    final tools = _tools.entries
        .map((e) => {
              'name': e.key,
              'description': e.value.description,
              'inputSchema': e.value.inputSchema,
            })
        .toList();

    return {'tools': tools};
  }

  /// Handle tools/call request.
  Future<Map<String, dynamic>> _handleToolsCall(Parameters params) async {
    final name = params['name'].asString;
    final rawArgs = params['arguments'].asMapOr(<String, dynamic>{});
    final arguments = Map<String, dynamic>.from(rawArgs);

    final tool = _tools[name];
    if (tool == null) {
      return {
        'isError': true,
        'content': [
          {'type': 'text', 'text': 'Unknown tool: $name'}
        ],
      };
    }

    try {
      final result = await tool.execute(arguments);
      return {
        'content': [
          {'type': 'text', 'text': result}
        ],
      };
    } catch (e) {
      return {
        'isError': true,
        'content': [
          {'type': 'text', 'text': 'Error: $e'}
        ],
      };
    }
  }
}

/// Base class for MCP tools.
abstract class McpTool {
  String get description;
  Map<String, dynamic> get inputSchema;
  Future<String> execute(Map<String, dynamic> arguments);
}
