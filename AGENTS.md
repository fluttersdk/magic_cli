# MAGIC CLI

Artisan-inspired CLI for scaffolding and managing Magic Framework projects.

## STRUCTURE

```
magic_cli/
├── bin/magic.dart             # Entry point
├── lib/src/
│   ├── commands/              # 16 command files (one per command)
│   ├── console/               # Console style utilities, command base
│   ├── helpers/               # File helpers, config editor
│   └── stubs/                 # StubLoader — template engine with case transforms
└── assets/stubs/              # .stub template files (31 templates)
```

## COMMANDS

| Command | Description |
|---------|-------------|
| `magic install` | Initialize project (--without-database, --without-events, --without-auth, --without-cache, --without-localization) |
| `magic key:generate` | Generate app encryption key → updates `.env` |
| `magic make:model Name` | Create model (-mcf for migration+controller+factory, -s for seeder, -a for all) |
| `magic make:controller Name` | Create controller (-r for resource with CRUD, -m for model binding) |
| `magic make:view Name` | Create view class (stateful option available) |
| `magic make:policy Name` | Create authorization policy |
| `magic make:migration create_X_table` | Create timestamped migration |
| `magic make:seeder Name` | Create seeder (auto-appends Seeder suffix) |
| `magic make:factory Name` | Create factory (auto-appends Factory suffix) |
| `magic make:provider Name` | Create service provider (auto-appends ServiceProvider suffix) |
| `magic make:lang code` | Create language JSON file in `assets/lang/` |
| `magic make:enum Name` | Create string-backed enum with value/label and selectOptions |
| `magic make:event Name` | Create MagicEvent subclass |
| `magic make:listener Name` | Create MagicListener with event binding |
| `magic make:middleware Name` | Create middleware class |
| `magic make:request Name` | Create form request with validation rules (auto-appends Request suffix) |

## CODE GENERATION

**Stub system**: `StubLoader` reads a `.stub` file from `assets/stubs/`, replaces placeholders, writes to target path.

Placeholders:

| Placeholder | Example Output |
|-------------|---------------|
| `{{ className }}` | `MonitorController` |
| `{{ tableName }}` | `monitors` |
| `{{ fileName }}` | `monitor_controller` |
| `{{ modelName }}` | `Monitor` |

`StubLoader` handles all case transforms internally — Pascal, snake, kebab. Callers pass the raw user input (e.g., `Monitor`); the loader derives all variants.

`-mcf` flag on `make:model` triggers three stub renders in sequence: migration, controller, factory. Each writes its own file and appends the provider/import where needed.

## CONFIG EDITOR

`magic install` and `make:provider` programmatically modify `pubspec.yaml` and target config files:

- Parses `pubspec.yaml` with `yaml` package, writes back with `yaml_writer`.
- Injects `import` statements at the top of `lib/config/app.dart`.
- Appends provider factory lambdas into the `providers` list inside the config map.
- Never overwrites existing entries — checks for duplicates before writing.


## GOTCHAS
1. Run commands from the Flutter project root — file paths resolve relative to `pubspec.yaml`.
2. `make:model -mcf` generates three files; if any stub fails, the others still write — no rollback.
3. Command is `install`, not `init` — `magic install` initializes the project.
4. `magic install --without-database` skips SQLite config but still writes `config/database.dart` as a stub.
5. Language codes for `make:lang` must match the asset path convention (`assets/lang/{code}.json`).
6. Auto-suffix commands (`make:factory`, `make:provider`, `make:seeder`, `make:request`) — passing `UserFactory` or `User` both work.
