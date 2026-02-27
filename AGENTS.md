# MAGIC CLI

Artisan-inspired CLI for scaffolding and managing Magic Framework projects.

## STRUCTURE

```
magic_cli/
├── bin/magic.dart             # Entry point
├── lib/src/
│   ├── commands/              # 16 command files (one per command)
│   ├── mcp/                   # MCP server tools and handlers
│   └── stub_loader.dart       # Template engine with case transforms
└── assets/stubs/              # .stub template files
```

## COMMANDS

| Command | Description |
|---------|-------------|
| `magic init` | Initialize project (--without-database, --without-events) |
| `magic key:generate` | Generate app key |
| `magic make:model Name` | Create model (-mcf for migration+controller+factory) |
| `magic make:controller Name` | Create controller |
| `magic make:view Name` | Create view class |
| `magic make:policy Name` | Create authorization policy |
| `magic make:migration create_X_table` | Create migration |
| `magic make:seeder Name` | Create seeder |
| `magic make:factory Name` | Create factory |
| `magic make:provider Name` | Create service provider |
| `magic make:lang code` | Create language file |
| `magic route:list` | List all routes |
| `magic config:list` | List config keys |
| `magic config:get key` | Get config value |
| `magic boost:install` | Set up MCP integration |
| `magic boost:mcp` | Run MCP server |
| `magic boost:update` | Update AI context files |

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

`magic init` and `make:provider` programmatically modify `pubspec.yaml` and target config files:

- Parses `pubspec.yaml` with `yaml` package, writes back with `yaml_writer`.
- Injects `import` statements at the top of `lib/config/app.dart`.
- Appends provider factory lambdas into the `providers` list inside the config map.
- Never overwrites existing entries — checks for duplicates before writing.

## MCP INTEGRATION

Three commands manage AI tooling:

| Command | Action |
|---------|--------|
| `boost:install` | Writes `.mcp.json` config, registers magic CLI as an MCP server |
| `boost:mcp` | Starts the MCP server (stdio transport); used by AI clients |
| `boost:update` | Regenerates `AGENTS.md` files from current project state |

MCP tools live in `lib/src/mcp/`. Each tool maps to a Magic Framework concept (models, routes, config) and returns structured JSON to the AI client.

## GOTCHAS

1. Run commands from the Flutter project root — file paths resolve relative to `pubspec.yaml`.
2. `make:model -mcf` generates three files; if any stub fails, the others still write — no rollback.
3. `boost:update` overwrites existing `AGENTS.md` files — commit before running.
4. `magic init --without-database` skips SQLite config but still writes `config/database.dart` as a stub.
5. Language codes for `make:lang` must match the asset path convention (`assets/lang/{code}.json`).
