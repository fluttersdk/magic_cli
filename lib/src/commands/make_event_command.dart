import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/stubs/event_stubs.dart';

/// Make Event Command.
///
/// Scaffolds a new MagicEvent subclass using the [eventStub] template.
///
/// ## Usage
///
/// ```bash
/// magic make:event UserLoggedIn
/// magic make:event Auth/TokenRefreshed
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/events/` with a dispatchable event class
/// that extends `MagicEvent`.
class MakeEventCommand extends GeneratorCommand {
  @override
  String get name => 'make:event';

  @override
  String get description => 'Create a new event class';

  @override
  String getDefaultNamespace() => 'lib/app/events';

  @override
  String getStub() => eventStub;

  /// Returns placeholder replacements for the event stub.
  ///
  /// Replaces `{{ className }}`, `{{ snakeName }}`, and `{{ description }}`
  /// from the parsed name.
  @override
  Map<String, String> getReplacements(String name) {
    final parsed = StringHelper.parseName(name);

    return {
      '{{ className }}': parsed.className,
      '{{ snakeName }}': StringHelper.toSnakeCase(parsed.className),
      '{{ description }}': 'the ${parsed.className} action occurs',
    };
  }
}
