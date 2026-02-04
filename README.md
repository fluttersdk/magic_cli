# Magic CLI ⚡

[![CI](https://github.com/fluttersdk/magic_cli/actions/workflows/ci.yml/badge.svg)](https://github.com/fluttersdk/magic_cli/actions/workflows/ci.yml)
[![Dart Version](https://img.shields.io/badge/Dart-3.4.0%2B-blue.svg)](https://dart.dev)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.22.0%2B-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**The Artisan-like CLI for Magic.** Scaffold controllers, models, views, migrations, and more with a single command.

---

## 🚀 Installation

```bash
dart pub global activate magic_cli
```

Ensure `~/.pub-cache/bin` is in your PATH.

---

## 📦 Quick Start

```bash
# Navigate to your Flutter project
cd my_app

# Initialize Magic with all features
magic init

# Or exclude specific features
magic init --without-database --without-events
```

---

## 🛠️ Available Commands

### Project Setup

| Command | Description |
|---------|-------------|
| `magic init` | Initialize Magic in an existing Flutter project |
| `magic key:generate` | Generate a new application encryption key |

### Make Commands

| Command | Description |
|---------|-------------|
| `magic make:model User` | Create an Eloquent model |
| `magic make:controller User` | Create a controller |
| `magic make:view Login` | Create a view class |
| `magic make:policy Post` | Create an authorization policy |
| `magic make:migration create_users_table` | Create a database migration |
| `magic make:seeder UserSeeder` | Create a database seeder |
| `magic make:factory UserFactory` | Create a model factory |
| `magic make:lang tr` | Create a language file |

---

## 📖 Command Details

### `magic init`

Initializes Magic in your Flutter project with the recommended directory structure and configuration.

```bash
magic init
```

**Options:**

| Option | Description |
|--------|-------------|
| `--without-database` | Skip database support |
| `--without-cache` | Skip caching |
| `--without-auth` | Skip authentication |
| `--without-events` | Skip event system |
| `--without-localization` | Skip localization/i18n |

---

### `magic make:model`

Creates an Eloquent-style model with optional related files.

```bash
magic make:model User
magic make:model Post --migration --controller --factory
magic make:model Comment -mcf  # Shorthand
```

**Options:**

| Option | Short | Description |
|--------|-------|-------------|
| `--migration` | `-m` | Create a migration file |
| `--controller` | `-c` | Create a controller |
| `--factory` | `-f` | Create a model factory |
| `--seeder` | `-s` | Create a seeder |
| `--all` | `-a` | Create all related files |

**Output:**
```
lib/app/models/user.dart
```

---

### `magic make:controller`

Creates a controller class.

```bash
magic make:controller UserController
magic make:controller User  # Auto-appends 'Controller'
magic make:controller Admin/Dashboard  # Nested path
```

**Options:**

| Option | Description |
|--------|-------------|
| `--resource`, `-r` | Create a resource controller with CRUD methods |
| `--model`, `-m` | Specify the model for resource controller |

**Output:**
```
lib/app/controllers/user_controller.dart
```

---

### `magic make:view`

Creates a view class with MagicStateMixin.

```bash
magic make:view LoginView
magic make:view Login  # Auto-appends 'View'
magic make:view Auth/Register  # Nested path
```

**Output:**
```
lib/resources/views/login_view.dart
```

---

### `magic make:migration`

Creates a database migration file.

```bash
magic make:migration create_users_table
magic make:migration add_email_to_users_table
```

**Options:**

| Option | Description |
|--------|-------------|
| `--create`, `-c` | The table to be created |
| `--table`, `-t` | The table to migrate |

**Output:**
```
lib/database/migrations/2024_01_15_120000_create_users_table.dart
```

---

### `magic make:policy`

Creates an authorization policy.

```bash
magic make:policy PostPolicy
magic make:policy Post  # Auto-appends 'Policy'
magic make:policy Comment --model=Comment
```

**Options:**

| Option | Description |
|--------|-------------|
| `--model`, `-m` | The model that the policy applies to |

**Output:**
```
lib/app/policies/post_policy.dart
```

---

### `magic make:seeder`

Creates a database seeder.

```bash
magic make:seeder UserSeeder
```

**Output:**
```
lib/database/seeders/user_seeder.dart
```

---

### `magic make:factory`

Creates a model factory.

```bash
magic make:factory UserFactory
magic make:factory User  # Auto-appends 'Factory'
```

**Output:**
```
lib/database/factories/user_factory.dart
```

---

### `magic make:lang`

Creates a language JSON file.

```bash
magic make:lang tr
magic make:lang es
```

**Output:**
```
assets/lang/tr.json
```

---

### `magic key:generate`

Generates a random encryption key for your application.

```bash
magic key:generate
```

Updates your `.env` file with:
```
APP_KEY=base64:randomGeneratedKey...
```

---

## 📁 Generated Structure

After running `magic init`, your project will have:

```
lib/
├── config/
│   ├── app.dart
│   ├── auth.dart
│   └── database.dart
├── app/
│   ├── controllers/
│   ├── models/
│   └── policies/
├── database/
│   ├── migrations/
│   ├── seeders/
│   └── factories/
├── resources/
│   └── views/
├── routes/
│   └── web.dart
└── main.dart
```

---

## 🔍 Inspection Commands

Commands for inspecting your project structure.

### `magic route:list`

Lists all registered routes in your application.

```bash
magic route:list
```

**Output:**
```
+---------------------+------------+----------+
| URI                 | Middleware | File     |
+---------------------+------------+----------+
| /                   | auth       | app.dart |
| /auth/login         | -          | web.dart |
| /dashboard          | auth       | app.dart |
+---------------------+------------+----------+
```

---

### `magic config:list`

Lists all configuration files and their keys.

```bash
magic config:list
magic config:list --verbose  # Show key previews
```

---

### `magic config:get`

Gets a specific configuration value using dot notation.

```bash
magic config:get app.name
magic config:get network.default
magic config:get app.url -s  # Show source
```

**Priority:** Project config → `.env` → Framework defaults

---

## 🚀 Magic Boost (AI Integration)

Magic Boost provides AI-powered development tools through MCP (Model Context Protocol).

### Setup

```bash
# Install Boost in your project
magic boost:install
```

This will:
- Create `.magic/guidelines/` with framework documentation
- Configure MCP server in your IDE (Cursor, VS Code)

### Commands

| Command | Description |
|---------|-------------|
| `magic boost:install` | Setup AI guidelines + MCP config |
| `magic boost:mcp` | Run the MCP server (stdio) |
| `magic boost:update` | Refresh guidelines to latest version |

---

### MCP Tools

The MCP server exposes these tools to AI assistants:

| Tool | Description |
|------|-------------|
| `app_info` | Get pubspec.yaml info (name, version, dependencies) |
| `list_routes` | List all application routes |
| `get_config` | Read config values with dot notation |
| `validate_wind` | Validate Wind UI utility classes |
| `search_docs` | Search Magic documentation |

---

### IDE Configuration

After running `boost:install`, your IDE's MCP config (`.cursor/mcp.json` or `.vscode/mcp.json`) will include:

```json
{
  "mcpServers": {
    "magic-boost": {
      "command": "dart",
      "args": ["/path/to/magic.dart", "boost:mcp"],
      "cwd": "/path/to/your/project"
    }
  }
}
```

**Manual Configuration:**

If auto-detection fails, manually add to your IDE's MCP config:

```json
{
  "mcpServers": {
    "magic-boost": {
      "command": "dart",
      "args": ["run", "magic_cli:magic", "boost:mcp"]
    }
  }
}
```

---

### Generated Guidelines

After installation, `.magic/guidelines/` contains:

```
.magic/
└── guidelines/
    ├── core.md      # Core Magic framework
    ├── wind.md      # Wind UI system
    ├── eloquent.md  # Eloquent models
    └── routing.md   # Routing system
```

These files provide context for AI assistants about your project's architecture.

---

## 🔌 Plugin Integration

### Using Magic CLI Base in Your Plugin

Magic CLI provides reusable infrastructure that plugins can extend:

```yaml
# pubspec.yaml in your plugin
dependencies:
  magic_cli:
    path: ../magic/plugins/magic_cli
```

### Creating Custom Commands

```dart
import 'package:magic_cli/magic_cli.dart';

class MyCommand extends Command {
  @override
  String get name => 'my:command';

  @override
  String get description => 'My custom command';

  @override
  void configure(ArgParser parser) {
    parser.addFlag('verbose', abbr: 'v');
  }

  @override
  Future<void> handle() async {
    // Use ConsoleStyle for output
    success('Operation completed!');
    info('Processing data...');
    warn('This is a warning');
    error('Something went wrong');

    // Interactive prompts
    final name = ask('What is your name?', defaultValue: 'User');
    final confirmed = confirm('Continue?', defaultValue: true);

    // Display tables
    table(['Name', 'Status'], [
      ['User', 'Active'],
      ['Admin', 'Inactive'],
    ]);

    // File operations
    if (FileHelper.fileExists('pubspec.yaml')) {
      final yaml = FileHelper.readYamlFile('pubspec.yaml');
      info('Project: ${yaml['name']}');
    }

    // Config editing
    ConfigEditor.addDependencyToPubspec(
      pubspecPath: 'pubspec.yaml',
      name: 'my_package',
      version: '^1.0.0',
    );
  }
}
```

### Available Helpers

#### ConsoleStyle
```dart
// Output methods
ConsoleStyle.success('Success message');  // ✓ with green
ConsoleStyle.error('Error message');      // ✗ with red
ConsoleStyle.info('Info message');        // ℹ with blue
ConsoleStyle.warning('Warning');          // ⚠ with yellow
ConsoleStyle.comment('Comment');          // Dimmed text

// Formatting
ConsoleStyle.header('Section Title');
ConsoleStyle.banner('Magic CLI', '1.0.0');
ConsoleStyle.line(char: '─', length: 50);
ConsoleStyle.keyValue('Name', 'Value');

// Tables
ConsoleStyle.table(['Header1', 'Header2'], [
  ['Row1Col1', 'Row1Col2'],
  ['Row2Col1', 'Row2Col2'],
]);
```

#### FileHelper
```dart
// File operations
FileHelper.fileExists('/path/to/file');
FileHelper.readFile('/path/to/file');
FileHelper.writeFile('/path/to/file', 'content');
FileHelper.copyFile(source, destination);
FileHelper.deleteFile('/path/to/file');

// Directory operations
FileHelper.directoryExists('/path');
FileHelper.ensureDirectoryExists('/path');

// YAML operations
final data = FileHelper.readYamlFile('config.yaml');
FileHelper.writeYamlFile('output.yaml', data);

// Project utilities
final root = FileHelper.findProjectRoot();
final relative = FileHelper.getRelativePath(from, to);
```

#### ConfigEditor
```dart
// Pubspec.yaml editing
ConfigEditor.addDependencyToPubspec(
  pubspecPath: 'pubspec.yaml',
  name: 'package_name',
  version: '^1.0.0',
);

ConfigEditor.removeDependencyFromPubspec(
  pubspecPath: 'pubspec.yaml',
  name: 'old_package',
);

ConfigEditor.updatePubspecValue(
  pubspecPath: 'pubspec.yaml',
  keyPath: ['environment', 'sdk'],
  value: '>=3.4.0 <4.0.0',
);

// Dart file editing
ConfigEditor.addImportToFile(
  filePath: 'lib/main.dart',
  importStatement: "import 'config/app.dart';",
);

ConfigEditor.insertCodeBeforePattern(
  filePath: 'lib/main.dart',
  pattern: RegExp(r'runApp\('),
  code: '  initializeApp();\n  ',
);

// Config file creation
ConfigEditor.createConfigFile(
  path: 'lib/config/my_config.dart',
  content: 'final config = {...};',
);
```

#### StubLoader
```dart
// Load templates
final stub = await StubLoader.load('template_name');
final content = StubLoader.replace(stub, {
  'className': 'User',
  'tableName': 'users',
});

// Or in one step
final result = await StubLoader.make('template_name', {
  'className': 'MyClass',
  'methodName': 'myMethod',
});

// Case transformers
StubLoader.toPascalCase('user_profile');  // UserProfile
StubLoader.toSnakeCase('UserProfile');    // user_profile
StubLoader.toKebabCase('UserProfile');    // user-profile
StubLoader.toCamelCase('user_profile');   // userProfile

// Custom search paths
StubLoader.loadSync('my_stub',
  searchPaths: ['/custom/path/to/stubs']);
```

### Stub Template Syntax

Create `.stub` files in your plugin's `assets/stubs/` directory:

```dart
// controller.stub
import 'package:flutter/material.dart';

class {{ className }}Controller {
  final String name = '{{ snakeName }}';

  Widget build() {
    return Container(
      child: Text('{{ className }}'),
    );
  }
}
```

Placeholders use `{{ variableName }}` syntax with flexible whitespace.

---

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines.

---

## 📄 License

Magic CLI is open-sourced software licensed under the [MIT license](LICENSE).
