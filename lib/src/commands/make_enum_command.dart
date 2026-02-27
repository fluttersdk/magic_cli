import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/stubs/enum_stubs.dart';

/// Make Enum Command.
///
/// Scaffolds a new string-backed enum class using the [enumStub] template.
///
/// ## Usage
///
/// ```bash
/// magic make:enum MonitorType
/// magic make:enum Status/OrderStatus
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/enums/` with value/label pattern,
/// `fromValue()` factory, and `selectOptions` getter.
class MakeEnumCommand extends GeneratorCommand {
  @override
  String get name => 'make:enum';

  @override
  String get description => 'Create a new enum';

  @override
  String getDefaultNamespace() => 'lib/app/enums';

  @override
  String getStub() => enumStub;

  /// Returns placeholder replacements for the enum stub.
  ///
  /// Replaces `{{ className }}` and `{{ snakeName }}` from the parsed name.
  @override
  Map<String, String> getReplacements(String name) {
    final parsed = StringHelper.parseName(name);

    return {
      '{{ className }}': parsed.className,
      '{{ snakeName }}': StringHelper.toSnakeCase(parsed.className),
    };
  }
}
