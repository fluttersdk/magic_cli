/// Factory stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:factory` command.
library;

/// Model factory stub — generates fake model instances for testing and seeding.
const String factoryStub = r'''
import 'package:magic/magic.dart';

// TODO: Import your model
// import '../../app/models/{{ snakeName }}.dart';

/// {{ className }}
///
/// Generates fake [{{ modelName }}] instances for seeding and testing.
class {{ className }} extends Factory<Model> {
  // TODO: Import and use your model class. Example:
  //   import '../../app/models/{{ snakeName }}.dart';
  //   class {{ className }} extends Factory<{{ modelName }}> {
  //   {{ modelName }} newInstance() => {{ modelName }}();
  @override
  Model newInstance() => throw UnimplementedError(
    'Import your model and override newInstance()',
  );

  @override
  Map<String, dynamic> definition() {
    return {
      'name': faker.person.name(),
      // Add more attributes here.
    };
  }

  // Custom states:
  //
  // {{ className }} inactive() {
  //   return state({'is_active': false}) as {{ className }};
  // }
}
''';
