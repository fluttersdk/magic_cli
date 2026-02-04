import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/magic_cli.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ConfigEditor', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('config_editor_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Pubspec Dependencies', () {
      test('addDependencyToPubspec() adds new dependency', () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        File(pubspecPath).writeAsStringSync('''
name: test_package
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
''');

        ConfigEditor.addDependencyToPubspec(
          pubspecPath: pubspecPath,
          name: 'http',
          version: '^1.0.0',
        );

        final content = File(pubspecPath).readAsStringSync();
        expect(content, contains('http: ^1.0.0'));
      });

      test('addDependencyToPubspec() updates existing dependency', () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        File(pubspecPath).writeAsStringSync('''
name: test_package
dependencies:
  http: ^0.13.0
''');

        ConfigEditor.addDependencyToPubspec(
          pubspecPath: pubspecPath,
          name: 'http',
          version: '^1.0.0',
        );

        final content = File(pubspecPath).readAsStringSync();
        expect(content, contains('http: ^1.0.0'));
        expect(content, isNot(contains('^0.13.0')));
      });

      test('removeDependencyFromPubspec() removes dependency', () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        File(pubspecPath).writeAsStringSync('''
name: test_package
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
''');

        ConfigEditor.removeDependencyFromPubspec(
          pubspecPath: pubspecPath,
          name: 'http',
        );

        final content = File(pubspecPath).readAsStringSync();
        expect(content, isNot(contains('http:')));
      });

      test('removeDependencyFromPubspec() does nothing if dependency not found',
          () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        final originalContent = '''
name: test_package
dependencies:
  flutter:
    sdk: flutter
''';
        File(pubspecPath).writeAsStringSync(originalContent);

        // Should not throw
        expect(
          () => ConfigEditor.removeDependencyFromPubspec(
            pubspecPath: pubspecPath,
            name: 'nonexistent',
          ),
          returnsNormally,
        );
      });

      test('addPathDependencyToPubspec() adds path dependency', () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        File(pubspecPath).writeAsStringSync('''
name: test_package
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
''');

        ConfigEditor.addPathDependencyToPubspec(
          pubspecPath: pubspecPath,
          name: 'my_plugin',
          path: './plugins/my_plugin',
        );

        final content = File(pubspecPath).readAsStringSync();
        expect(content, contains('my_plugin:'));
        expect(content, contains('path: ./plugins/my_plugin'));
      });

      test('addPathDependencyToPubspec() updates existing dependency to path',
          () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        File(pubspecPath).writeAsStringSync('''
name: test_package
dependencies:
  my_plugin: ^1.0.0
''');

        ConfigEditor.addPathDependencyToPubspec(
          pubspecPath: pubspecPath,
          name: 'my_plugin',
          path: './plugins/my_plugin',
        );

        final content = File(pubspecPath).readAsStringSync();
        expect(content, contains('path: ./plugins/my_plugin'));
        expect(content, isNot(contains('^1.0.0')));
      });
    });

    group('Pubspec Value Updates', () {
      test('updatePubspecValue() updates nested value', () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        File(pubspecPath).writeAsStringSync('''
name: test_package
version: 1.0.0
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

        ConfigEditor.updatePubspecValue(
          pubspecPath: pubspecPath,
          keyPath: ['environment', 'sdk'],
          value: '>=3.4.0 <4.0.0',
        );

        final content = File(pubspecPath).readAsStringSync();
        expect(content, contains('>=3.4.0 <4.0.0'));
      });

      test('updatePubspecValue() creates missing keys', () {
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        File(pubspecPath).writeAsStringSync('''
name: test_package
version: 1.0.0
''');

        ConfigEditor.updatePubspecValue(
          pubspecPath: pubspecPath,
          keyPath: ['environment', 'sdk'],
          value: '>=3.0.0 <4.0.0',
        );

        final content = File(pubspecPath).readAsStringSync();
        expect(content, contains('environment:'));
        expect(content, contains('sdk:'));
      });
    });

    group('Dart File Modifications', () {
      test('addImportToFile() adds import if not present', () {
        final dartFile = path.join(tempDir.path, 'main.dart');
        File(dartFile).writeAsStringSync('''
import 'package:flutter/material.dart';

void main() {}
''');

        ConfigEditor.addImportToFile(
          filePath: dartFile,
          importStatement: "import 'package:http/http.dart';",
        );

        final content = File(dartFile).readAsStringSync();
        expect(content, contains("import 'package:http/http.dart';"));
      });

      test('addImportToFile() does not duplicate existing import', () {
        final dartFile = path.join(tempDir.path, 'main.dart');
        final originalContent = '''
import 'package:flutter/material.dart';
import 'package:http/http.dart';

void main() {}
''';
        File(dartFile).writeAsStringSync(originalContent);

        ConfigEditor.addImportToFile(
          filePath: dartFile,
          importStatement: "import 'package:http/http.dart';",
        );

        final content = File(dartFile).readAsStringSync();
        final importCount = RegExp(r"import 'package:http/http\.dart';")
            .allMatches(content)
            .length;
        expect(importCount, equals(1));
      });

      test('insertCodeBeforePattern() inserts code before match', () {
        final dartFile = path.join(tempDir.path, 'main.dart');
        File(dartFile).writeAsStringSync('''
void main() {
  runApp(MyApp());
}
''');

        ConfigEditor.insertCodeBeforePattern(
          filePath: dartFile,
          pattern: RegExp(r'runApp\('),
          code: '  // Initialize\n  ',
        );

        final content = File(dartFile).readAsStringSync();
        expect(content, contains('// Initialize\n  runApp('));
      });

      test('insertCodeAfterPattern() inserts code after match', () {
        final dartFile = path.join(tempDir.path, 'main.dart');
        File(dartFile).writeAsStringSync('''
void main() {
  runApp(MyApp());
}
''');

        ConfigEditor.insertCodeAfterPattern(
          filePath: dartFile,
          pattern: RegExp(r'runApp\(MyApp\(\)\);'),
          code: '\n  // Done',
        );

        final content = File(dartFile).readAsStringSync();
        expect(content, contains('runApp(MyApp());\n  // Done'));
      });

      test('insertCodeBeforePattern() does nothing if pattern not found', () {
        final dartFile = path.join(tempDir.path, 'main.dart');
        final originalContent = 'void main() {}';
        File(dartFile).writeAsStringSync(originalContent);

        ConfigEditor.insertCodeBeforePattern(
          filePath: dartFile,
          pattern: RegExp(r'nonexistent'),
          code: 'inserted code',
        );

        final content = File(dartFile).readAsStringSync();
        expect(content, equals(originalContent));
      });
    });

    group('Config File Creation', () {
      test('createConfigFile() creates file with content', () {
        final configPath = path.join(tempDir.path, 'config', 'app.dart');

        ConfigEditor.createConfigFile(
          path: configPath,
          content: '''
class AppConfig {
  static const String version = '1.0.0';
}
''',
        );

        final file = File(configPath);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), contains('AppConfig'));
      });

      test('createConfigFile() creates parent directories', () {
        final configPath =
            path.join(tempDir.path, 'lib', 'config', 'nested', 'app.dart');

        ConfigEditor.createConfigFile(
          path: configPath,
          content: 'class Config {}',
        );

        expect(File(configPath).existsSync(), isTrue);
        expect(Directory(path.dirname(configPath)).existsSync(), isTrue);
      });
    });
  });
}
