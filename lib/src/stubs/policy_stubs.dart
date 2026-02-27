/// Policy stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:policy` command.
library;

/// Policy stub — Gate-based authorization for a model resource.
const String policyStub = r'''
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

import '../models/{{ snakeName }}.dart';

/// {{ className }}
///
/// Defines authorization rules for [{{ modelName }}] resources.
class {{ className }} extends Policy {
  @override
  void register() {
    Gate.define('view-{{ snakeName }}', _view);
    Gate.define('create-{{ snakeName }}', _create);
    Gate.define('update-{{ snakeName }}', _update);
    Gate.define('delete-{{ snakeName }}', _delete);
  }

  /// Determine if the user can view the [{{ modelName }}].
  bool _view(Authenticatable user, dynamic arguments) {
    // TODO: Implement your authorization logic.
    return true;
  }

  /// Determine if the user can create a [{{ modelName }}].
  bool _create(Authenticatable user, dynamic arguments) {
    // TODO: Implement your authorization logic.
    return true;
  }

  /// Determine if the user can update the [{{ modelName }}].
  bool _update(Authenticatable user, dynamic arguments) {
    // TODO: Implement your authorization logic.
    return true;
  }

  /// Determine if the user can delete the [{{ modelName }}].
  bool _delete(Authenticatable user, dynamic arguments) {
    // TODO: Implement your authorization logic.
    return true;
  }
}
''';
