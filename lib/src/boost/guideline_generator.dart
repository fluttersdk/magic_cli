import 'dart:io';

/// Generates AI guideline files for Magic projects.
///
/// Creates `.magic/guidelines/` directory with mockup content for:
/// - core.md - Core Magic framework guidelines
/// - wind.md - Wind UI system guidelines
/// - eloquent.md - Eloquent model guidelines
/// - routing.md - Routing guidelines
class GuidelineGenerator {
  final String projectRoot;

  GuidelineGenerator(this.projectRoot);

  /// Generate all guideline files.
  Future<void> generate() async {
    final guidelinesDir = Directory('$projectRoot/.magic/guidelines');

    if (!guidelinesDir.existsSync()) {
      guidelinesDir.createSync(recursive: true);
    }

    await _writeGuideline('core.md', _coreContent);
    await _writeGuideline('wind.md', _windContent);
    await _writeGuideline('eloquent.md', _eloquentContent);
    await _writeGuideline('routing.md', _routingContent);
  }

  Future<void> _writeGuideline(String filename, String content) async {
    final file = File('$projectRoot/.magic/guidelines/$filename');
    await file.writeAsString(content);
  }

  // Mockup content - to be filled later
  static const _coreContent = '''
# Magic Core Guidelines

> PROTOTYPE: Mockup content for Magic Core guidelines.

## Overview
Magic is a Laravel-style Flutter framework that provides familiar patterns
for PHP developers building mobile applications.

## Key Concepts
- Service Container
- Facades (Magic, Auth, Http, Cache, etc.)
- Service Providers
- MagicController with MagicStateMixin

## Usage
```dart
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

// Access services via facades
await Auth.login(credentials, user);
final response = await Http.get('/api/users');
```
''';

  static const _windContent = '''
# Wind UI Guidelines

> PROTOTYPE: Mockup content for Wind UI guidelines.

## Overview
Wind is a Tailwind CSS-like utility system for Flutter.

## Core Widgets
- WDiv - Universal container (replaces Container, Row, Column)
- WText - Typography widget
- WButton - Interactive button
- WAnchor - State wrapper for hover/focus

## Utility Classes
```dart
WDiv(
  className: "flex gap-4 p-4 bg-gray-100 rounded-lg",
  children: [...],
)
```
''';

  static const _eloquentContent = '''
# Eloquent Model Guidelines

> PROTOTYPE: Mockup content for Eloquent model guidelines.

## Overview
Magic provides Laravel-style Eloquent models with:
- HasTimestamps mixin
- InteractsWithPersistence mixin
- Attribute casting

## Example
```dart
class User extends Model with HasTimestamps, InteractsWithPersistence {
  @override String get table => 'users';
  @override String get resource => 'users';
  @override List<String> get fillable => ['name', 'email'];
}
```
''';

  static const _routingContent = '''
# Routing Guidelines

> PROTOTYPE: Mockup content for routing guidelines.

## Overview
Magic uses a fluent routing API similar to Laravel.

## Route Registration
```dart
MagicRoute.page('/dashboard', () => DashboardView());
MagicRoute.group(
  prefix: '/admin',
  middleware: ['auth'],
  routes: () {
    MagicRoute.page('/users', () => UsersView());
  },
);
```

## Navigation
```dart
MagicRoute.to('/dashboard');
MagicRoute.push('/user/1');
MagicRoute.back();
```
''';
}
