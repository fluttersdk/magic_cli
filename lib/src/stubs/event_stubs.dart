/// Event stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:event` command.
library;

/// MagicEvent subclass stub — a dispatchable application event.
const String eventStub = r'''
import 'package:magic/magic.dart';

/// {{ className }} event.
///
/// Dispatched when {{ description }}.
///
/// ## Dispatch
///
/// ```dart
/// Event.dispatch({{ className }}());
/// ```
class {{ className }} extends MagicEvent {
  {{ className }}();
}
''';
