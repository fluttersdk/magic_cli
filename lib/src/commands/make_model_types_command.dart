import 'dart:io';

import 'package:fluttersdk_magic_cli/src/console/command.dart';

/// The Make Model Types Command.
///
/// Generates typed accessors for an existing model based on its
/// `fillable` and `casts` definitions.
///
/// ## Usage
///
/// ```bash
/// magic make:model-types Order
/// magic make:model-types User
/// ```
///
/// ## Output
///
/// Updates the model file, replacing the Typed Accessors section with
/// generated getters and setters based on fillable fields and casts.
class MakeModelTypesCommand extends Command {
  @override
  String get name => 'make:model-types';

  @override
  String get description =>
      'Generate typed accessors for a model based on fillable/casts';

  /// Execute the console command.
  @override
  Future<void> handle() async {
    if (arguments.rest.isEmpty) {
      error('Please provide a model name.');
      error('Usage: magic make:model-types <ModelName>');
      return;
    }

    final modelName = arguments.rest.first;
    final snakeName = _toSnakeCase(modelName);
    final filePath = 'lib/app/models/$snakeName.dart';

    final file = File(filePath);
    if (!file.existsSync()) {
      error('Model file not found: $filePath');
      return;
    }

    final content = file.readAsStringSync();

    // Parse fillable and casts
    final fillable = _parseFillable(content);
    final casts = _parseCasts(content);

    if (fillable.isEmpty) {
      error('No fillable fields found in model.');
      return;
    }

    info('Found ${fillable.length} fillable fields');
    info('Found ${casts.length} cast definitions');

    // Generate typed accessors
    final accessors = _generateAccessors(fillable, casts);

    // Find and replace the Typed Accessors section
    final updatedContent = _replaceAccessorsSection(content, accessors);

    if (updatedContent == content) {
      error('Could not find Typed Accessors section to update.');
      return;
    }

    // Write updated file
    file.writeAsStringSync(updatedContent);
    info('Updated typed accessors in: $filePath');
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

  /// Convert snake_case to camelCase.
  String _toCamelCase(String input) {
    final parts = input.split('_');
    if (parts.isEmpty) return input;
    return parts.first +
        parts
            .skip(1)
            .map((p) =>
                p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
            .join('');
  }

  /// Parse fillable list from model content.
  List<String> _parseFillable(String content) {
    // Match: List<String> get fillable => [...];
    final regex = RegExp(
      r"get fillable\s*=>\s*\[([\s\S]*?)\];",
      multiLine: true,
    );
    final match = regex.firstMatch(content);
    if (match == null) return [];

    final listContent = match.group(1)!;
    final stringRegex = RegExp(r"'([^']+)'");
    return stringRegex.allMatches(listContent).map((m) => m.group(1)!).toList();
  }

  /// Parse casts map from model content.
  Map<String, String> _parseCasts(String content) {
    // Match: Map<String, String> get casts => {...};
    final regex = RegExp(
      r"get casts\s*=>\s*\{([\s\S]*?)\};",
      multiLine: true,
    );
    final match = regex.firstMatch(content);
    if (match == null) return {};

    final mapContent = match.group(1)!;
    final entryRegex = RegExp(r"'([^']+)'\s*:\s*'([^']+)'");
    final result = <String, String>{};
    for (final m in entryRegex.allMatches(mapContent)) {
      result[m.group(1)!] = m.group(2)!;
    }
    return result;
  }

  /// Generate typed accessors code.
  String _generateAccessors(List<String> fillable, Map<String, String> casts) {
    final buffer = StringBuffer();

    for (final field in fillable) {
      final camelName = _toCamelCase(field);
      final castType = casts[field];
      final dartType = _castToDartType(castType);
      final isNullable = dartType != 'bool' && dartType != 'int';

      buffer.writeln();
      buffer.writeln('  /// Get the $field value.');

      if (dartType == 'bool') {
        buffer.writeln(
            "  $dartType get $camelName => (getAttribute('$field') ?? 0) == 1;");
        buffer.writeln(
            "  set $camelName($dartType value) => setAttribute('$field', value ? 1 : 0);");
      } else if (dartType == 'int' && !isNullable) {
        buffer.writeln(
            "  $dartType get $camelName => (getAttribute('$field') ?? 0) as $dartType;");
        buffer.writeln(
            "  set $camelName($dartType value) => setAttribute('$field', value);");
      } else {
        final nullSuffix = isNullable ? '?' : '';
        buffer.writeln(
            "  $dartType$nullSuffix get $camelName => getAttribute('$field') as $dartType$nullSuffix;");
        if (castType == 'datetime') {
          buffer.writeln(
              "  set $camelName(dynamic value) => setAttribute('$field', value);");
        } else {
          buffer.writeln(
              "  set $camelName($dartType$nullSuffix value) => setAttribute('$field', value);");
        }
      }
    }

    return buffer.toString();
  }

  /// Map cast type to Dart type.
  String _castToDartType(String? castType) {
    switch (castType) {
      case 'datetime':
        return 'Carbon';
      case 'json':
        return 'Map<String, dynamic>';
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      default:
        return 'String';
    }
  }

  /// Replace the Typed Accessors section with generated code.
  String _replaceAccessorsSection(String content, String accessors) {
    // Find the section between "// Typed Accessors" and "// Static Helpers"
    final startMarker = RegExp(
      r'// [-]+\s*\n\s*// Typed Accessors\s*\n\s*// [-]+',
    );
    final endMarker = RegExp(
      r'\n\s*// [-]+\s*\n\s*// Static Helpers',
    );

    final startMatch = startMarker.firstMatch(content);
    final endMatch = endMarker.firstMatch(content);

    if (startMatch == null || endMatch == null) {
      return content;
    }

    final before = content.substring(0, startMatch.end);
    final after = content.substring(endMatch.start);

    return '$before\n$accessors$after';
  }
}
