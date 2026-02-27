/// Seeder stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:seeder` command.
library;

/// Database seeder stub — seeds initial or sample data.
const String seederStub = r'''
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// {{ className }}
///
/// Seeds the database with sample data.
class {{ className }} extends Seeder {
  @override
  Future<void> run() async {
    // Use factories to create data:
    // await {{ modelName }}Factory().count(10).create();
  }
}
''';
