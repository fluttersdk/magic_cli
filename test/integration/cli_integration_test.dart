import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';
import 'package:path/path.dart' as path;

/// Integration tests for CLI base functionality
void main() {
  group('CLI Integration Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cli_integration_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Full Command Registration and Execution', () {
      test('Kernel registers and executes commands', () async {
        final kernel = Kernel();
        final testCommand = TestCommand();

        kernel.register(testCommand);

        // Command should be registered
        expect(kernel, isNotNull);

        // Command can be executed
        await expectLater(testCommand.handle(), completes);
      });

      test('Multiple commands can be registered', () {
        final kernel = Kernel();
        kernel.register(TestCommand());
        kernel.register(AnotherTestCommand());

        expect(kernel, isNotNull);
      });
    });

    group('Stub Loading from Custom Paths', () {
      test('StubLoader loads from custom search paths', () {
        final customStubDir = path.join(tempDir.path, 'stubs');
        Directory(customStubDir).createSync();

        final stubPath = path.join(customStubDir, 'custom.stub');
        File(stubPath).writeAsStringSync('Hello {{ name }}!');

        final content = StubLoader.loadSync('custom',
          searchPaths: [customStubDir]);

        expect(content, equals('Hello {{ name }}!'));
      });

      test('StubLoader prioritizes first search path', () {
        final dir1 = path.join(tempDir.path, 'stubs1');
        final dir2 = path.join(tempDir.path, 'stubs2');
        Directory(dir1).createSync();
        Directory(dir2).createSync();

        File(path.join(dir1, 'test.stub')).writeAsStringSync('From dir1');
        File(path.join(dir2, 'test.stub')).writeAsStringSync('From dir2');

        final content = StubLoader.loadSync('test',
          searchPaths: [dir1, dir2]);

        expect(content, equals('From dir1'));
      });
    });

    group('ConsoleStyle Integration', () {
      test('All output methods work together', () {
        final messages = <String>[];

        messages.add(ConsoleStyle.success('Operation completed'));
        messages.add(ConsoleStyle.error('Error occurred'));
        messages.add(ConsoleStyle.info('Information'));
        messages.add(ConsoleStyle.warning('Warning'));
        messages.add(ConsoleStyle.comment('Comment'));

        expect(messages.length, equals(5));
        expect(messages[0], contains('Operation completed'));
        expect(messages[1], contains('Error occurred'));
      });

      test('Table formatting works with various data', () {
        final result = ConsoleStyle.table(
          ['Command', 'Description', 'Status'],
          [
            ['key:generate', 'Generate app key', 'Active'],
            ['make:controller', 'Create controller', 'Active'],
            ['route:list', 'List all routes', 'Active'],
          ],
        );

        expect(result, contains('Command'));
        expect(result, contains('key:generate'));
        expect(result, contains('make:controller'));
      });
    });

    group('FileHelper and ConfigEditor Integration', () {
      test('FileHelper and ConfigEditor work together', () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        FileHelper.writeFile(pubspecPath, '''
name: test_app
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
''');

        ConfigEditor.addDependencyToPubspec(
          pubspecPath: pubspecPath,
          name: 'test_package',
          version: '^1.0.0',
        );

        final content = FileHelper.readFile(pubspecPath);
        expect(content, contains('test_package: ^1.0.0'));
      });

      test('FileHelper detects project root', () {
        // Create a mock project structure
        final projectDir = path.join(tempDir.path, 'project');
        final libDir = path.join(projectDir, 'lib', 'src');
        Directory(libDir).createSync(recursive: true);

        FileHelper.writeFile(
          path.join(projectDir, 'pubspec.yaml'),
          'name: test_project',
        );

        final foundRoot = FileHelper.findProjectRoot(startFrom: libDir);
        expect(foundRoot, equals(projectDir));
      });
    });

    group('Case Transformers', () {
      test('All case transformers work correctly', () {
        expect(StubLoader.toPascalCase('user_profile'), equals('UserProfile'));
        expect(StubLoader.toSnakeCase('UserProfile'), equals('user_profile'));
        expect(StubLoader.toKebabCase('UserProfile'), equals('user-profile'));
        expect(StubLoader.toCamelCase('user_profile'), equals('userProfile'));
      });
    });

    group('End-to-End Stub Generation', () {
      test('Complete stub generation workflow', () {
        final stubDir = path.join(tempDir.path, 'stubs');
        Directory(stubDir).createSync();

        // Create a stub template
        final stubPath = path.join(stubDir, 'controller.stub');
        File(stubPath).writeAsStringSync('''
import 'package:flutter/material.dart';

class {{ className }}Controller {
  final String name = '{{ name }}';

  Widget {{ methodName }}() {
    return Container();
  }
}
''');

        // Generate from stub
        final result = StubLoader.makeSync(
          'controller',
          {
            'className': 'User',
            'name': 'user',
            'methodName': 'build',
          },
          searchPaths: [stubDir],
        );

        expect(result, contains('class UserController'));
        expect(result, contains("final String name = 'user';"));
        expect(result, contains('Widget build()'));
      });
    });
  });
}

// Test command implementations
class TestCommand extends Command {
  @override
  String get name => 'test';

  @override
  String get description => 'Test command';

  @override
  Future<void> handle() async {
    success('Test command executed');
  }
}

class AnotherTestCommand extends Command {
  @override
  String get name => 'another';

  @override
  String get description => 'Another test command';

  @override
  Future<void> handle() async {
    info('Another test command executed');
  }
}
