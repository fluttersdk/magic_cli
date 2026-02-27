/// Provider stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:provider` command.
library;

/// ServiceProvider stub — register() for bindings, boot() for async setup.
const String providerStub = r'''
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// {{ className }}
///
/// Service provider for {{ description }}.
///
/// ## Registration
///
/// Add to your `app.providers` config:
///
/// ```dart
/// 'providers': [
///   (app) => {{ className }}(app),
/// ],
/// ```
class {{ className }} extends ServiceProvider {
  {{ className }}(super.app);

  /// Register bindings into the IoC container.
  ///
  /// Keep this sync — no async calls, no resolving other services.
  @override
  void register() {
    //
  }

  /// Bootstrap any application services.
  ///
  /// Called after all providers have registered — safe to resolve dependencies.
  @override
  Future<void> boot() async {
    //
  }
}
''';
