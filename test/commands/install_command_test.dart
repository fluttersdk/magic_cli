import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/src/commands/install_command.dart';

/// Testable subclass — injects temp project root to avoid hitting real filesystem.
class _TestInstallCommand extends InstallCommand {
  _TestInstallCommand(this._testRoot);

  final String _testRoot;

  @override
  String getProjectRoot() => _testRoot;
}

/// Creates a minimal Flutter project scaffold in the given directory.
void _createMinimalFlutterProject(Directory dir) {
  // pubspec.yaml
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: test_app
description: A test Flutter project.
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
''');

  // lib/main.dart
  Directory('${dir.path}/lib').createSync(recursive: true);
  File('${dir.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: Scaffold()));
}
''');
}

void main() {
  group('InstallCommand', () {
    late Directory tempDir;
    late _TestInstallCommand cmd;
    late ArgParser parser;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('magic_test_install_');
      _createMinimalFlutterProject(tempDir);
      cmd = _TestInstallCommand(tempDir.path);
      parser = ArgParser();
      cmd.configure(parser);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    // -----------------------------------------------------------------------
    // Metadata
    // -----------------------------------------------------------------------

    test('name is install', () {
      expect(cmd.name, 'install');
    });

    test('description is not empty', () {
      expect(cmd.description, isNotEmpty);
    });

    // -----------------------------------------------------------------------
    // Directory structure — full install
    // -----------------------------------------------------------------------

    test('creates all expected app directories', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      final expectedDirs = [
        'lib/app/controllers',
        'lib/app/models',
        'lib/app/enums',
        'lib/app/middleware',
        'lib/app/policies',
        'lib/app/providers',
        'lib/app/listeners',
        'lib/app/events',
        'lib/resources/views',
        'lib/routes',
        'lib/config',
      ];

      for (final dir in expectedDirs) {
        expect(
          Directory('${tempDir.path}/$dir').existsSync(),
          isTrue,
          reason: '$dir should exist after install',
        );
      }
    });

    test('creates database directories by default', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      final dbDirs = [
        'lib/database/migrations',
        'lib/database/seeders',
        'lib/database/factories',
      ];

      for (final dir in dbDirs) {
        expect(
          Directory('${tempDir.path}/$dir').existsSync(),
          isTrue,
          reason: '$dir should exist after full install',
        );
      }
    });

    test('creates assets/lang directory by default', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      expect(
        Directory('${tempDir.path}/assets/lang').existsSync(),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // --without-database flag
    // -----------------------------------------------------------------------

    test('skips lib/database dirs when --without-database', () async {
      cmd.arguments = parser.parse(['--without-database']);
      await cmd.handle();

      expect(
        Directory('${tempDir.path}/lib/database').existsSync(),
        isFalse,
        reason: 'lib/database should NOT exist with --without-database',
      );
    });

    test('skips lib/config/database.dart when --without-database', () async {
      cmd.arguments = parser.parse(['--without-database']);
      await cmd.handle();

      expect(
        File('${tempDir.path}/lib/config/database.dart').existsSync(),
        isFalse,
      );
    });

    // -----------------------------------------------------------------------
    // --without-localization flag
    // -----------------------------------------------------------------------

    test('skips assets/lang when --without-localization', () async {
      cmd.arguments = parser.parse(['--without-localization']);
      await cmd.handle();

      expect(
        Directory('${tempDir.path}/assets/lang').existsSync(),
        isFalse,
      );
    });

    // -----------------------------------------------------------------------
    // --without-auth flag
    // -----------------------------------------------------------------------

    test('skips lib/config/auth.dart when --without-auth', () async {
      cmd.arguments = parser.parse(['--without-auth']);
      await cmd.handle();

      expect(
        File('${tempDir.path}/lib/config/auth.dart').existsSync(),
        isFalse,
      );
    });

    // -----------------------------------------------------------------------
    // Config files
    // -----------------------------------------------------------------------

    test('creates lib/config/app.dart', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      expect(
        File('${tempDir.path}/lib/config/app.dart').existsSync(),
        isTrue,
      );
    });

    test('app config contains appConfig and providers list', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      final content =
          File('${tempDir.path}/lib/config/app.dart').readAsStringSync();
      expect(content, contains('appConfig'));
      expect(content, contains('providers'));
      expect(content, contains('RouteServiceProvider'));
    });

    test('creates lib/config/auth.dart by default', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      expect(
        File('${tempDir.path}/lib/config/auth.dart').existsSync(),
        isTrue,
      );
    });

    test('creates lib/config/database.dart by default', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      expect(
        File('${tempDir.path}/lib/config/database.dart').existsSync(),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Starter files
    // -----------------------------------------------------------------------

    test('creates lib/app/providers/route_service_provider.dart', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      expect(
        File(
          '${tempDir.path}/lib/app/providers/route_service_provider.dart',
        ).existsSync(),
        isTrue,
      );
    });

    test('creates lib/app/providers/app_service_provider.dart', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      expect(
        File(
          '${tempDir.path}/lib/app/providers/app_service_provider.dart',
        ).existsSync(),
        isTrue,
      );
    });

    test('creates lib/routes/app.dart', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      expect(
        File('${tempDir.path}/lib/routes/app.dart').existsSync(),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // main.dart bootstrap injection
    // -----------------------------------------------------------------------

    test('injects Magic.init into main.dart', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      final content = File('${tempDir.path}/lib/main.dart').readAsStringSync();
      expect(content, contains('Magic.init'));
    });

    test(
        'main.dart injection is idempotent — runs install twice, Magic.init appears once',
        () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      // Run again — should not double-inject.
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      final content = File('${tempDir.path}/lib/main.dart').readAsStringSync();
      final count = 'Magic.init'.allMatches(content).length;
      expect(count, 1, reason: 'Magic.init must appear exactly once');
    });

    test('injects fluttersdk_magic import into main.dart', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      final content = File('${tempDir.path}/lib/main.dart').readAsStringSync();
      expect(content,
          contains("import 'package:magic/magic.dart'"));
    });

    test('injects config/app.dart import into main.dart', () async {
      cmd.arguments = parser.parse([]);
      await cmd.handle();

      final content = File('${tempDir.path}/lib/main.dart').readAsStringSync();
      expect(content, contains("import 'config/app.dart'"));
    });
  });
}
