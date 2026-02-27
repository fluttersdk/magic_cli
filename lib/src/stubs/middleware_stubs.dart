/// Middleware stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:middleware` command.
library;

/// Middleware stub — MagicMiddleware with handle() hook.
const String middlewareStub = r'''
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// {{ className }}
///
/// HTTP middleware — intercepts navigation and performs checks before
/// allowing the request to proceed.
///
/// ## Registration
///
/// ```dart
/// // In Kernel:
/// Kernel.register('{{ snakeName }}', () => {{ className }}());
///
/// // On a route:
/// MagicRoute.page('/protected', () => controller.index())
///     .middleware(['{{ snakeName }}']);
/// ```
class {{ className }} extends MagicMiddleware {
  @override
  Future<void> handle(void Function() next) async {
    // TODO: Add your middleware logic here.
    // Call next() to allow the request to proceed.
    next();
  }
}
''';
