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
  void up() {
    Schema.create('{{ tableName }}', (Blueprint table) {
      table.id();
      // Add your columns here.
      table.timestamps();
    });
  }

  @override
  void down() {
    Schema.dropIfExists('{{ tableName }}');
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
  void up() {
    // Define your migration here.
  }

  @override
  void down() {
    // Reverse the migration.
  }
}
''';
