import 'dart:io';

import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';

/// The Make Policy Command.
///
/// Scaffolds a new authorization policy file using `.stub` templates.
///
/// ## Usage
///
/// ```bash
/// magic make:policy PostPolicy
/// magic make:policy Post                      # Auto-appends 'Policy'
/// magic make:policy CommentPolicy --model=Comment
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/policies/` with CRUD ability definitions.
class MakePolicyCommand extends Command {
  @override
  String get name => 'make:policy';

  @override
  String get description => 'Create a new authorization policy class';

  @override
  void configure(ArgParser parser) {
    parser.addOption(
      'model',
      abbr: 'm',
      help: 'The model that the policy applies to',
    );
  }

  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a policy name.');
      error('Usage: magic make:policy <Name> [--model=ModelName]');
      return;
    }

    final policyName = arguments.rest.first;
    // Strip 'Policy' suffix case-insensitively if present
    final baseName = policyName.toLowerCase().endsWith('policy')
        ? policyName.substring(0, policyName.length - 6)
        : policyName;
    final className = '${baseName}Policy';

    // Determine model name from option or policy name
    final modelOption = arguments['model'] as String?;
    final modelName = modelOption ?? className.replaceAll('Policy', '');
    final snakeName = _toSnakeCase(modelName);
    final fileName = _toSnakeCase(className);

    // Validate names
    if (!RegExp(r'^[A-Z][a-zA-Z0-9]*$')
        .hasMatch(className.replaceAll('Policy', ''))) {
      error('Policy name must be PascalCase (e.g., Post, CommentPolicy).');
      return;
    }

    // Create policies directory if it doesn't exist
    final dir = Directory('lib/app/policies');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      comment('Created directory: lib/app/policies/');
    }

    // Check if file already exists
    final file = File('${dir.path}/$fileName.dart');
    if (file.existsSync()) {
      error('Policy already exists: lib/app/policies/$fileName.dart');
      return;
    }

    // Generate file content using stub
    final content = _generateFromStub(className, modelName, snakeName);

    if (content.isEmpty) {
      error('Failed to generate policy content.');
      return;
    }

    // Write file
    file.writeAsStringSync(content);
    newLine();
    success('Created policy: lib/app/policies/$fileName.dart');
  }

  /// Convert PascalCase to snake_case.
  String _toSnakeCase(String input) {
    final result = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
        result.write('_');
      }
      result.write(char.toLowerCase());
    }
    return result.toString();
  }

  /// Generate policy content from stub file.
  String _generateFromStub(
    String className,
    String modelName,
    String snakeName,
  ) {
    // Generate camelCase version for variable names
    final camelName = modelName[0].toLowerCase() + modelName.substring(1);

    final replacements = <String, String>{
      'className': className,
      'modelName': modelName,
      'snakeName': snakeName,
      'camelName': camelName,
    };

    try {
      return StubLoader.makeSync('policy', replacements);
    } on StubNotFoundException catch (e) {
      error('Error: ${e.toString()}');
      return '';
    }
  }
}
