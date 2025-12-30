import 'dart:io';
import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/src/console/command.dart';

class Kernel {
  final Map<String, Command> _commands = {};

  /// Register a command.
  void register(Command command) {
    _commands[command.name] = command;
  }

  /// Handle the incoming arguments.
  Future<void> handle(List<String> args) async {
    if (args.isEmpty) {
      _printHelp();
      return;
    }

    final commandName = args[0];

    // Check for global flags like --help
    if (commandName == '--help' || commandName == '-h') {
      _printHelp();
      return;
    }

    final command = _commands[commandName];

    if (command == null) {
      stderr.writeln('Command "$commandName" not found.');
      _printHelp();
      return;
    }

    // Parse arguments for this specific command
    final parser = ArgParser();
    command.configure(parser);

    // We strip the command name to parse the rest
    final commandArgs = args.sublist(1);

    try {
      final results = parser.parse(commandArgs);
      command.arguments = results;
      await command.handle();
    } catch (e) {
      stderr.writeln('Error: $e');
      stderr.writeln('Usage: magic ${command.name}');
      // parser.usage would be better here if exposed
    }
  }

  void _printHelp() {
    stdout.writeln('Magic CLI 0.0.1');
    stdout.writeln('');
    stdout.writeln('Usage: magic <command> [arguments]');
    stdout.writeln('');
    stdout.writeln('Available commands:');

    // Sort commands alphabetically
    final sortedKeys = _commands.keys.toList()..sort();

    for (final key in sortedKeys) {
      final cmd = _commands[key]!;
      // Padding for alignment
      final paddedName = key.padRight(20);
      stdout.writeln('  $paddedName ${cmd.description}');
    }
  }
}
