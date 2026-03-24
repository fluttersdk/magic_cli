---
path: "lib/src/commands/**/*.dart"
---

# Command Conventions

## GeneratorCommand Contract
Every `make:*` command extends `GeneratorCommand` and overrides:
- `name` → `'make:feature'`
- `description` → `'Create a new feature class'`
- `getDefaultNamespace()` → output directory (e.g., `'lib/app/controllers'`)
- `getStub()` → stub name without `.stub` extension
- `getReplacements(String name)` → custom placeholder map
- `getProjectRoot()` → `_testRoot ?? super.getProjectRoot()`

## Constructor Pattern
```dart
final String? _testRoot;
MakeXCommand({String? testRoot}) : _testRoot = testRoot;
```
Every command accepts optional `testRoot` for test isolation.

## configure() Must Call Super
```dart
@override
void configure(ArgParser parser) {
  super.configure(parser);  // Inherits --force flag
  parser.addFlag('custom', abbr: 'c', negatable: false);
}
```
Always `super.configure(parser)` first — skipping loses `--force` inheritance.

## Suffix Handling
Commands that auto-append suffixes (Controller, Factory, Seeder, Provider, Request, Policy):
- Strip existing suffix before re-appending to prevent `UserControllerController`
- Use private `_resolveClassName()` or `_stripSuffix()` + `_withSuffix()` helpers

## Command Chaining
`MakeModelCommand` chains child generators via:
```dart
await MakeMigrationCommand(testRoot: _testRoot).runWith([migrationName, '--create=$tableName']);
```
Always pass `testRoot: _testRoot` to child commands — omitting causes tests to touch real filesystem.

## Non-Generator Commands
`InstallCommand` and `KeyGenerateCommand` extend `Command` directly (not `GeneratorCommand`).
They handle file creation manually without stubs.

## Nested Path Support
`make:controller Admin/Dashboard` → `StringHelper.parseName()` returns `(directory: 'admin', className: 'Dashboard', fileName: 'dashboard')`.
Directory segments are snake_cased. Class name preserves PascalCase.
