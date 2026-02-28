import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';

/// Make Middleware Command.
///
/// Scaffolds a new Magic middleware class using the [middlewareStub] template.
///
/// ## Usage
///
/// ```bash
/// magic make:middleware EnsureAuthenticated
/// magic make:middleware Admin/RoleCheck
/// ```
///
/// ## Output
///
/// Creates a file in `lib/app/middleware/` with full nested path support.
class MakeMiddlewareCommand extends GeneratorCommand {
  @override
  String get name => 'make:middleware';

  @override
  String get description => 'Create a new middleware class';

  @override
  String getDefaultNamespace() => 'lib/app/middleware';

  @override
  String getStub() => 'middleware';

  /// Returns placeholder replacements for the middleware stub.
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
