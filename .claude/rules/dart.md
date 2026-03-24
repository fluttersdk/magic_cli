---
path: "**/*.dart"
---

# Dart Conventions

## Imports
- Always `package:magic_cli/src/...` — never relative imports
- Order: `dart:` stdlib → external packages (`args`, `path`, `yaml`) → internal `package:magic_cli/...`
- Alias `package:path/path.dart` as `path`

## Naming
- Classes: `PascalCase` — Files: `snake_case` — Methods: `camelCase` — Private: `_prefix`
- CLI command names: `namespace:action` (e.g., `make:controller`, `key:generate`)
- One class per file, filename matches class in snake_case

## Doc Comments
- `///` on all public classes and methods
- Class-level: usage examples in `## Usage` + `## Output` sections with code blocks
- Method-level: single-line summary, then `@param`, `@return`, `@throws` as needed

## Error Handling
- File operations: throw `FileSystemException('message', path)`
- Missing CLI args: print error via `error()` and return — do not throw
- Kernel catches `FormatException` + generic `Exception`, sets `exitCode = 1`

## Static Utility Classes
- Constructor: `const ClassName._()` to prevent instantiation
- All methods `static`, no instance state
- Follows: `FileHelper`, `ConsoleStyle`, `ConfigEditor`, `JsonEditor`, `StringHelper`
