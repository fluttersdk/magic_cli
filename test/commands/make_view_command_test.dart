import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/src/commands/make_view_command.dart';

void main() {
  group('MakeViewCommand', () {
    late Directory tempDir;
    late MakeViewCommand cmd;
    late ArgParser parser;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('magic_test_view_');
      cmd = MakeViewCommand(testRoot: tempDir.path);
      parser = ArgParser();
      cmd.configure(parser);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    // -----------------------------------------------------------------------
    // Basic scaffolding
    // -----------------------------------------------------------------------

    test('generates login_view.dart from "Login" input', () async {
      cmd.arguments = parser.parse(['Login']);

      await cmd.handle();

      final file = File(
        '${tempDir.path}/lib/resources/views/login_view.dart',
      );
      expect(file.existsSync(), isTrue);
    });

    test('generated file contains LoginView class extending MagicView',
        () async {
      cmd.arguments = parser.parse(['Login']);

      await cmd.handle();

      final content = File(
        '${tempDir.path}/lib/resources/views/login_view.dart',
      ).readAsStringSync();
      expect(content, contains('class LoginView extends MagicView'));
    });

    test('auto-appends View suffix when not present', () async {
      cmd.arguments = parser.parse(['Login']);

      await cmd.handle();

      final file = File(
        '${tempDir.path}/lib/resources/views/login_view.dart',
      );
      expect(file.existsSync(), isTrue);
    });

    test('does not double-append View when already present', () async {
      cmd.arguments = parser.parse(['LoginView']);

      await cmd.handle();

      final file = File(
        '${tempDir.path}/lib/resources/views/login_view.dart',
      );
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('class LoginView extends MagicView'));
      expect(content, isNot(contains('LoginViewView')));
    });

    // -----------------------------------------------------------------------
    // Nested paths
    // -----------------------------------------------------------------------

    test('nested path creates correct directory structure', () async {
      cmd.arguments = parser.parse(['Auth/Register']);

      await cmd.handle();

      final file = File(
        '${tempDir.path}/lib/resources/views/auth/register_view.dart',
      );
      expect(file.existsSync(), isTrue);
    });

    test('nested path file contains RegisterView class', () async {
      cmd.arguments = parser.parse(['Auth/Register']);

      await cmd.handle();

      final content = File(
        '${tempDir.path}/lib/resources/views/auth/register_view.dart',
      ).readAsStringSync();
      expect(content, contains('class RegisterView extends MagicView'));
    });

    // -----------------------------------------------------------------------
    // Stateful stub
    // -----------------------------------------------------------------------

    test('--stateful flag uses stateful stub (MagicStatefulView)', () async {
      cmd.arguments = parser.parse(['Dashboard', '--stateful']);

      await cmd.handle();

      final content = File(
        '${tempDir.path}/lib/resources/views/dashboard_view.dart',
      ).readAsStringSync();
      expect(content, contains('MagicStatefulView'));
    });

    test('basic stub uses stateless MagicView, not MagicStatefulView',
        () async {
      cmd.arguments = parser.parse(['Dashboard']);

      await cmd.handle();

      final content = File(
        '${tempDir.path}/lib/resources/views/dashboard_view.dart',
      ).readAsStringSync();
      expect(content, contains('MagicView'));
      expect(content, isNot(contains('MagicStatefulView')));
    });

    test('stateful stub contains onInit and onClose lifecycle hooks', () async {
      cmd.arguments = parser.parse(['Dashboard', '--stateful']);

      await cmd.handle();

      final content = File(
        '${tempDir.path}/lib/resources/views/dashboard_view.dart',
      ).readAsStringSync();
      expect(content, contains('void onInit()'));
      expect(content, contains('void onClose()'));
    });

    // -----------------------------------------------------------------------
    // --force flag
    // -----------------------------------------------------------------------

    test('returns error when file already exists without --force', () async {
      // First create
      cmd.arguments = parser.parse(['Login']);
      await cmd.handle();

      final file = File(
        '${tempDir.path}/lib/resources/views/login_view.dart',
      );
      file.writeAsStringSync('ORIGINAL');

      // Second attempt — should NOT overwrite
      final cmd2 = MakeViewCommand(testRoot: tempDir.path);
      cmd2.arguments = parser.parse(['Login']);
      await cmd2.handle();

      expect(file.readAsStringSync(), equals('ORIGINAL'));
    });

    test('overwrites existing file with --force flag', () async {
      // First create
      cmd.arguments = parser.parse(['Login']);
      await cmd.handle();

      final file = File(
        '${tempDir.path}/lib/resources/views/login_view.dart',
      );
      file.writeAsStringSync('ORIGINAL');

      // Second attempt with --force
      final cmd2 = MakeViewCommand(testRoot: tempDir.path);
      final parser2 = ArgParser();
      cmd2.configure(parser2);
      cmd2.arguments = parser2.parse(['Login', '--force']);
      await cmd2.handle();

      expect(file.readAsStringSync(), isNot(equals('ORIGINAL')));
      expect(file.readAsStringSync(), contains('LoginView'));
    });

    // -----------------------------------------------------------------------
    // Missing argument
    // -----------------------------------------------------------------------

    test('returns early when no name argument provided', () async {
      cmd.arguments = parser.parse([]);

      // Should not throw — just print error
      expect(() async => cmd.handle(), returnsNormally);
    });
  });
}
