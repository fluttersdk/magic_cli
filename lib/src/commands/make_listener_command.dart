import 'package:args/args.dart';
import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/stubs/listener_stubs.dart';

/// Make Listener Command.
///
/// Scaffolds a new MagicListener subclass using the [listenerStub] template.
///
/// ## Usage
///
/// ```bash
/// magic make:listener AuthRestore --event=UserLoggedInEvent
/// magic make:listener AuthRestore           # Defaults to MagicEvent
/// magic make:listener Auth/RestoreSession   # Nested path
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/listeners/` with a handler class that
/// extends `MagicListener<TEvent>`.
class MakeListenerCommand extends GeneratorCommand {
  @override
  String get name => 'make:listener';

  @override
  String get description => 'Create a new event listener class';

  @override
  String getDefaultNamespace() => 'lib/app/listeners';

  @override
  String getStub() => listenerStub;

  /// Registers the `--event` option in addition to the inherited `--force` flag.
  ///
  /// @param parser The argument parser to configure.
  @override
  void configure(ArgParser parser) {
    super.configure(parser);
    parser.addOption(
      'event',
      abbr: 'e',
      help: 'The event class the listener handles',
    );
  }

  /// Returns placeholder replacements for the listener stub.
  ///
  /// Resolves `{{ eventClass }}` from `--event` option or defaults to
  /// `MagicEvent`. When a custom event class is provided, the
  /// `{{ eventSnakeName }}` import placeholder is populated; otherwise the
  /// import line is removed since `MagicEvent` ships with the framework.
  @override
  Map<String, String> getReplacements(String name) {
    final parsed = StringHelper.parseName(name);
    final eventClass = option('event') ?? 'MagicEvent';

    // 1. Derive snake_case version of the event class for the import path.
    final eventSnakeName = StringHelper.toSnakeCase(eventClass);

    // 2. When no custom event class is given, strip the local import line
    //    entirely — MagicEvent is already exported by the framework package.
    final eventImportLine = eventClass == 'MagicEvent'
        ? ''
        : "import '../events/$eventSnakeName.dart';";

    return {
      '{{ className }}': parsed.className,
      '{{ snakeName }}': StringHelper.toSnakeCase(parsed.className),
      '{{ eventClass }}': eventClass,
      "import '../events/{{ eventSnakeName }}.dart';": eventImportLine,
    };
  }
}
