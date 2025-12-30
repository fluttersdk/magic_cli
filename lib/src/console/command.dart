import 'dart:io';

import 'package:args/args.dart';

/// Abstract base class for all Magic CLI commands.
///
/// This class serves as the blueprint for creating custom artisan commands.
/// It provides access to input arguments and helper methods for styling output.
abstract class Command {
  /// The signature of the command (e.g., 'key:generate').
  ///
  /// This is the name users will type into the console to invoke this command.
  String get name;

  /// The description of the command.
  ///
  /// This text is displayed when running the `magic list` help command.
  String get description;

  /// The arguments parsed from the command line.
  ///
  /// Use this to access positional arguments and flags passed by the user.
  late ArgResults arguments;

  /// Configure the command arguments.
  ///
  /// override this method to define flags and options using the [ArgParser].
  void configure(ArgParser parser) {}

  /// Write a standard info message to stdout.
  void info(String message) => stdout.writeln(message);

  /// Write a comment or debug message to stdout.
  void comment(String message) => stdout.writeln(message);

  /// Write an error message to stderr.
  void error(String message) => stderr.writeln(message);

  /// Execute the command.
  ///
  /// This contains the core logic of your command.
  Future<void> handle();
}
