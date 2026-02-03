import 'dart:io';

import 'package:args/args.dart';
import '../helpers/console_style.dart';

/// Abstract base class for all Magic CLI commands.
///
/// This class serves as the blueprint for creating custom artisan commands.
/// It provides access to input arguments and helper methods for styling output
/// in Laravel Artisan style.
///
/// ## Usage
///
/// ```dart
/// class KeyGenerateCommand extends Command {
///   @override
///   String get name => 'key:generate';
///
///   @override
///   String get description => 'Generate a new application key';
///
///   @override
///   void configure(ArgParser parser) {
///     parser.addFlag('show', help: 'Display the key instead of modifying files');
///   }
///
///   @override
///   Future<void> handle() async {
///     success('Application key generated successfully!');
///   }
/// }
/// ```
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
  /// Override this method to define flags and options using the [ArgParser].
  void configure(ArgParser parser) {}

  // Output methods with Laravel Artisan-style formatting

  /// Write a plain line to stdout.
  void line(String message) => stdout.writeln(message);

  /// Write an info message with blue color.
  void info(String message) => stdout.writeln(ConsoleStyle.info(message));

  /// Write a success message with green checkmark.
  void success(String message) => stdout.writeln(ConsoleStyle.success(message));

  /// Write a warning message with yellow color.
  void warn(String message) => stdout.writeln(ConsoleStyle.warning(message));

  /// Write an error message with red color to stderr.
  void error(String message) => stderr.writeln(ConsoleStyle.error(message));

  /// Write a comment or debug message in dim text.
  void comment(String message) => stdout.writeln(ConsoleStyle.comment(message));

  /// Write an empty line.
  void newLine() => stdout.writeln(ConsoleStyle.newLine());

  /// Display data as a formatted table.
  ///
  /// Example:
  /// ```dart
  /// table(['Name', 'Status'], [
  ///   ['User', 'Active'],
  ///   ['Admin', 'Inactive'],
  /// ]);
  /// ```
  void table(List<String> headers, List<List<String>> rows) {
    stdout.writeln(ConsoleStyle.table(headers, rows));
  }

  /// Display a key-value pair with alignment.
  ///
  /// Example: `Name:           John Doe`
  void keyValue(String key, String value, {int keyWidth = 20}) {
    stdout.writeln(ConsoleStyle.keyValue(key, value, keyWidth: keyWidth));
  }

  // Interactive input methods

  /// Ask the user a question and return their response.
  ///
  /// If [defaultValue] is provided and the user enters nothing, returns the default.
  String ask(String question, {String? defaultValue}) {
    if (defaultValue != null) {
      stdout.write('$question [$defaultValue]: ');
    } else {
      stdout.write('$question: ');
    }

    final input = stdin.readLineSync();
    if (input == null || input.trim().isEmpty) {
      return defaultValue ?? '';
    }
    return input.trim();
  }

  /// Ask the user a yes/no question.
  ///
  /// Returns `true` for yes, `false` for no.
  /// If [defaultValue] is provided, pressing enter returns that value.
  bool confirm(String question, {bool? defaultValue}) {
    final defaultText = defaultValue == null
        ? 'y/n'
        : defaultValue
            ? 'Y/n'
            : 'y/N';
    stdout.write('$question [$defaultText]: ');

    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == null || input.isEmpty) {
      return defaultValue ?? false;
    }

    return input == 'y' || input == 'yes';
  }

  /// Present a list of choices and return the selected option.
  ///
  /// If [defaultIndex] is provided, pressing enter selects that option.
  String choice(String question, List<String> options, {int? defaultIndex}) {
    stdout.writeln(question);
    for (var i = 0; i < options.length; i++) {
      final marker = defaultIndex == i ? '>' : ' ';
      stdout.writeln(' $marker [$i] ${options[i]}');
    }

    if (defaultIndex != null) {
      stdout.write('Select [${defaultIndex}]: ');
    } else {
      stdout.write('Select: ');
    }

    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) {
      if (defaultIndex != null &&
          defaultIndex >= 0 &&
          defaultIndex < options.length) {
        return options[defaultIndex];
      }
      return options[0];
    }

    final index = int.tryParse(input);
    if (index != null && index >= 0 && index < options.length) {
      return options[index];
    }

    // Invalid input, return default or first option
    if (defaultIndex != null &&
        defaultIndex >= 0 &&
        defaultIndex < options.length) {
      return options[defaultIndex];
    }
    return options[0];
  }

  // Argument access helpers

  /// Get the value of a named option.
  ///
  /// Returns `null` if the option doesn't exist.
  dynamic option(String name) {
    if (!arguments.options.contains(name)) {
      return null;
    }
    return arguments[name];
  }

  /// Get a positional argument by index.
  ///
  /// Returns `null` if the index is out of bounds.
  String? argument(int index) {
    if (index >= arguments.rest.length) {
      return null;
    }
    return arguments.rest[index];
  }

  /// Check if a named option was provided.
  bool hasOption(String name) {
    return arguments.wasParsed(name);
  }

  /// Execute the command.
  ///
  /// This contains the core logic of your command.
  Future<void> handle();
}
