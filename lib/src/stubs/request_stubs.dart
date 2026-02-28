/// Request stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:request` command.
library;

/// Form request stub — validation rules for a controller action.
const String requestStub = r'''
import 'package:magic/magic.dart';

/// {{ className }}
///
/// Validates incoming data for the {{ actionDescription }} action.
class {{ className }} {
  {{ className }}(this.data);

  /// The incoming request data.
  final Map<String, dynamic> data;

  /// Validation rules applied to the incoming data.
  Map<String, List<Rule>> rules() {
    return {
      // 'name': [Required(), Min(2), Max(255)],
      // 'email': [Required(), Email()],
    };
  }

  /// Validate the request data.
  ///
  /// Returns a [Validator] instance for inspection.
  Validator validate() {
    return Validator.make(data, rules());
  }
}
''';
