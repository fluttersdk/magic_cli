/// Migration stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:migration` command.
library;

/// Create migration stub — creates a new table with standard columns.
const String migrationCreateStub = r'''
import 'package:magic/magic.dart';

/// Migration: {{ fullName }}
///
/// Creates the {{ tableName }} table.
class {{ className }} extends Migration {
  @override
  String get name => '{{ fullName }}';

  @override
  Future<void> up() async {
    await Schema.create('{{ tableName }}', (Blueprint table) {
      table.id();
      // Add your columns here.
      table.timestamps();
    });
  }

  @override
  Future<void> down() async {
    await Schema.dropIfExists('{{ tableName }}');
  }
}
''';

/// Blank migration stub — for altering tables or custom operations.
const String migrationStub = r'''
import 'package:magic/magic.dart';

/// Migration: {{ fullName }}
class {{ className }} extends Migration {
  @override
  String get name => '{{ fullName }}';

  @override
  Future<void> up() async {
    // Define your migration here.
  }

  @override
  Future<void> down() async {
    // Reverse the migration.
  }
}
''';
