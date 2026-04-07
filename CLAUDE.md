# Magic CLI — Artisan-Inspired Flutter Scaffolding Tool

Dart CLI plugin for the Magic Framework. Provides `magic` command with Laravel Artisan-style scaffolding (`make:*`), project initialization (`install`), utilities (`key:generate`), and AI integration (`boost:*`).

**Version:** Check pubspec.yaml · **Dart:** >=3.4.0 · **Flutter:** >=3.22.0

## Commands

| Command | Description |
|---------|-------------|
| `flutter test --coverage` | Run all tests with coverage |
| `flutter analyze --no-fatal-infos` | Static analysis |
| `dart format --set-exit-if-changed .` | Format check (CI mode) |
| `dart format .` | Format all code |

## Architecture

**Pattern**: Kernel → Command Registry → GeneratorCommand (Laravel Artisan-inspired)

```
bin/magic.dart                        # Entry: create Kernel, register commands, dispatch
lib/src/
├── console/
│   ├── kernel.dart                   # Command registry & dispatcher — heart of CLI
│   ├── command.dart                  # Base: abstract with IO helpers, arg parsing, prompts
│   ├── generator_command.dart        # Base for make:* — stub loading & placeholder replacement
│   └── string_helper.dart            # Case transforms (pascal/snake/camel), pluralization, path parsing
├── commands/                         # 16+ concrete commands (one per file)
├── stubs/
│   ├── stub_loader.dart              # Multi-strategy stub resolution + {{ placeholder }} replacement
│   └── install_stubs.dart            # Install-specific stub utilities
└── helpers/                          # Static utilities: file I/O, YAML, console styling, config editing

assets/stubs/                         # .stub templates (17 generator + 19 install stubs)
```

**Lifecycle**: `bin/magic.dart` → `Kernel.handle(args)` → lookup command by `args[0]` → `command.configure(parser)` → parse args → `command.handle()`

**Command hierarchy**: `Command` (base) → `GeneratorCommand` (make:* base) → concrete commands. `InstallCommand` and `KeyGenerateCommand` extend `Command` directly.

## Adding a New Command

1. Create `lib/src/commands/make_{name}_command.dart` extending `GeneratorCommand`
2. Override: `name`, `description`, `getDefaultNamespace()`, `getStub()`, `getReplacements()`
3. Create `assets/stubs/{name}.stub` with `{{ className }}`, `{{ namespace }}` placeholders
4. Register in `bin/magic.dart`: `kernel.register(MakeNameCommand())`
5. Export in `lib/magic_cli.dart`
6. Add test in `test/commands/`

## Stub System

- Templates in `assets/stubs/*.stub` with `{{ placeholder }}` syntax (flexible whitespace)
- `StubLoader` resolves stubs via: `MAGIC_CLI_STUBS_DIR` env → `.dart_tool/package_config.json` → `Platform.script` walk-up → fallback paths
- `GeneratorCommand` handles `{{ className }}` and `{{ namespace }}` automatically; custom placeholders via `getReplacements()`
- Nested paths supported: `make:controller Admin/Dashboard` → `lib/app/controllers/admin/dashboard_controller.dart`

## Testing

- **TDD mandatory** — write failing test first, then implement, then refactor. No code without a covering test.
- Tests mirror source in `test/` — `test/commands/`, `test/console/`, `test/helpers/`, `test/integration/`
- Test isolation: commands accept `testRoot` parameter to override `FileHelper.findProjectRoot()`
- Stub override in tests: set `MAGIC_CLI_STUBS_DIR` env var
- Integration tests in `test/integration/cli_integration_test.dart` — full CLI flow

## Post-Change Checklist

After ANY source code change, sync **before committing**:

1. **`CHANGELOG.md`** — Add entry under `[Unreleased]` section
2. **`README.md`** — Update the relevant section for any change that affects user-facing behavior (new commands, flags, options, output format, examples)
3. **`AGENTS.md`** — Update command table and gotchas if command behavior changed
4. **`assets/stubs/`** — Update or create stubs for new/changed generators

## Gotchas

| Mistake | Fix |
|---------|-----|
| Run CLI from wrong directory | Must run from Flutter project root — paths resolve relative to `pubspec.yaml` |
| `make:model -mcf` partial failure | No rollback — if migration succeeds but factory fails, migration file persists |
| Double suffix: `make:controller UserController` | Safe — auto-suffix commands strip existing suffix before re-appending |
| `{{ classname }}` typo in stub | Placeholders are case-sensitive — `{{ className }}` only. Typos leave raw placeholder text |
| `testRoot` not passed to child commands | `MakeModelCommand` chains generators — each child must receive `testRoot` or it uses real project root |
| `StringHelper.toSnakeCase('HTTPServer')` | Produces `h_t_t_p_server` — regex splits on each uppercase after lowercase |
| `Command.ask()` / `confirm()` in CI | Uses `stdin.readLineSync()` — blocks in non-interactive environments |
| `InstallCommand` doesn't use `GeneratorCommand` | It's standalone — patterns differ (manual file creation, no stub base class) |
| Manual command registration only | No auto-discovery — new commands must be registered in `bin/magic.dart` |

## CI

- `ci.yml`: push/PR → `flutter pub get` → `flutter analyze` → `dart format --set-exit-if-changed` → `flutter test --coverage`
- `publish.yml`: git tag `v*.*.*` → auto-publish to pub.dev
