/// Listener stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:listener` command.
library;

/// MagicListener stub — handles a specific MagicEvent subclass.
const String listenerStub = r'''
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

import '../events/{{ eventSnakeName }}.dart';

/// {{ className }}
///
/// Handles [{{ eventClass }}] events.
///
/// ## Registration
///
/// ```dart
/// // In EventServiceProvider:
/// EventDispatcher.instance.register({{ eventClass }}, [
///   () => {{ className }}(),
/// ]);
/// ```
class {{ className }} extends MagicListener<{{ eventClass }}> {
  @override
  Future<void> handle({{ eventClass }} event) async {
    // TODO: Implement your event handling logic here.
  }
}
''';
