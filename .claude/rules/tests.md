---
path: "test/**/*_test.dart"
---

# Test Conventions

## Setup Pattern
```dart
late Directory tempDir;
late MyCommand cmd;
late ArgParser parser;

setUp(() {
  tempDir = Directory.systemTemp.createTempSync('magic_test_feature_');
  cmd = MyCommand(testRoot: tempDir.path);
  parser = ArgParser();
  cmd.configure(parser);
});

tearDown(() {
  tempDir.deleteSync(recursive: true);
});
```
Every test group gets a fresh `tempDir`. Always clean up in `tearDown`.

## Test Isolation
- Pass `testRoot: tempDir.path` to ALL commands — never let tests touch real project
- For chained commands (`make:model -mcf`), child commands must also receive `testRoot`
- Set `MAGIC_CLI_STUBS_DIR` env var to override stub resolution paths in tests

## Running Commands in Tests
```dart
cmd.arguments = parser.parse(['Monitor', '--resource']);
await cmd.handle();
```
Always `parser.parse()` before `cmd.handle()` — populates `cmd.arguments`.

## Assertions
- File existence: `expect(File('...').existsSync(), isTrue)`
- Content check: `expect(file.readAsStringSync(), contains('class MonitorController'))`
- Negative: `expect(content, isNot(contains('MonitorControllerController')))`
- Count: `expect(dir.listSync().length, equals(1))`

## Test Structure Per Command
1. Name/description getters
2. Argument parsing (flags, options, positional args)
3. File generation — verify file exists at correct path
4. Content verification — class name, imports, placeholders replaced
5. Edge cases — nested paths, duplicate suffixes, `--force` overwrite, missing args

## Integration Tests
`Directory.current` must be changed and restored in `try`/`finally`:
```dart
Directory.current = tempDir;
try { await kernel.handle(args); }
finally { Directory.current = originalDir; }
```
Create a dummy `pubspec.yaml` in `tempDir` — `findProjectRoot()` needs it.

## No Mocking Libraries
Use real filesystem with temp dirs. No `mockito`, no code generation — mock by constructing commands with `testRoot`.
