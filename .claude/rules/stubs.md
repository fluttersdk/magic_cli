---
path: "assets/stubs/**/*.stub"
---

# Stub Template Conventions

## Placeholder Syntax
- Use `{{ key }}` with spaces inside braces — flexible whitespace (`{{key}}` also works)
- Case-sensitive: `{{ className }}` only — `{{ classname }}` is a different placeholder
- Unreplaced placeholders remain as raw text in output — no validation or warnings

## Auto-Handled Placeholders
- `{{ className }}` — PascalCase class name (from last path segment)
- `{{ namespace }}` — output directory path (e.g., `lib/app/controllers`)

## Custom Placeholders
Defined per command via `getReplacements()`:
- `{{ tableName }}` — plural snake_case (model)
- `{{ snakeName }}` — snake_case of class name
- `{{ resourceName }}` — lower-case resource name
- `{{ description }}` — human-readable description

## Naming Convention
- `{feature}.stub` — default template (e.g., `controller.stub`)
- `{feature}.{variant}.stub` — variant selected by flag (e.g., `controller.resource.stub`, `view.stateful.stub`, `migration.create.stub`)

## Content Style
- Start with `import 'package:magic/magic.dart';` (or relevant Magic imports)
- Class docstring: `/// {{ className }} description.`
- Private fields with `_prefix`
- `// TODO:` comments for user customization points
- Trailing commas on multi-line params
- Match the coding style of the parent Magic framework
