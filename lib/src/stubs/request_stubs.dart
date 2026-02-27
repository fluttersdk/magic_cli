/// Request stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:request` command.
library;

/// Form request stub — validation rules for a controller action.
const String requestStub = r'''
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// {{ className }}
///
/// Validates incoming data for the {{ actionDescription }} action.
class {{ className }} extends FormRequest {
  const {{ className }}(super.data);

  /// Validation rules applied to the incoming data.
  @override
  Map<String, List<ValidationRule>> rules() {
    return {
      // 'name': rules([Required(), Min(2), Max(255)], field: 'name'),
      // 'email': rules([Required(), Email()], field: 'email'),
    };
  }
}
''';
