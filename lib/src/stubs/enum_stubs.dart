/// Enum stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:enum` command.
library;

/// String-backed enum stub with value/label pattern and SelectOption support.
const String enumStub = r'''
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// {{ className }} enum.
enum {{ className }} {
  sample('sample', 'Sample');

  const {{ className }}(this.value, this.label);

  /// The raw string value stored in the database / API.
  final String value;

  /// The human-readable label for display in the UI.
  final String label;

  /// Find a [{{ className }}] by its [value], returning `null` if not found.
  static {{ className }}? fromValue(String? value) {
    if (value == null) return null;
    try {
      return {{ className }}.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }

  /// Build a list of [SelectOption]s for use in dropdowns.
  static List<SelectOption<{{ className }}>> get selectOptions {
    return {{ className }}.values
        .map((e) => SelectOption(value: e, label: e.label))
        .toList();
  }
}
''';
