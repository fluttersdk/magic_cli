import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/magic_cli.dart';
import 'package:path/path.dart' as path;

void main() {
  group('StubLoader', () {
    late Directory tempDir;
    late String tempStubsDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('stub_loader_test_');
      tempStubsDir = path.join(tempDir.path, 'stubs');
      Directory(tempStubsDir).createSync();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Basic Loading', () {
      test('load() reads stub file content', () async {
        final stubPath = path.join(tempStubsDir, 'test.stub');
        File(stubPath).writeAsStringSync('class {{ className }} {}');

        final content =
            await StubLoader.load('test', searchPaths: [tempStubsDir]);
        expect(content, equals('class {{ className }} {}'));
      });

      test('loadSync() reads stub file content synchronously', () {
        final stubPath = path.join(tempStubsDir, 'test.stub');
        File(stubPath).writeAsStringSync('class {{ className }} {}');

        final content =
            StubLoader.loadSync('test', searchPaths: [tempStubsDir]);
        expect(content, equals('class {{ className }} {}'));
      });

      test('load() throws StubNotFoundException when stub not found', () {
        expect(
          () async =>
              await StubLoader.load('nonexistent', searchPaths: [tempStubsDir]),
          throwsA(isA<StubNotFoundException>()),
        );
      });

      test('exists() returns true for existing stub', () {
        final stubPath = path.join(tempStubsDir, 'exists.stub');
        File(stubPath).writeAsStringSync('content');

        expect(
            StubLoader.exists('exists', searchPaths: [tempStubsDir]), isTrue);
      });

      test('exists() returns false for non-existent stub', () {
        expect(StubLoader.exists('nonexistent', searchPaths: [tempStubsDir]),
            isFalse);
      });
    });

    group('Placeholder Replacement', () {
      test('replace() handles single placeholder', () {
        final stub = 'Hello {{ name }}!';
        final result = StubLoader.replace(stub, {'name': 'World'});
        expect(result, equals('Hello World!'));
      });

      test('replace() handles multiple placeholders', () {
        final stub = '{{ greeting }} {{ name }}!';
        final result = StubLoader.replace(stub, {
          'greeting': 'Hello',
          'name': 'World',
        });
        expect(result, equals('Hello World!'));
      });

      test('replace() handles placeholders with varying whitespace', () {
        final stub = '{{name}} {{  name  }} {{ name}}';
        final result = StubLoader.replace(stub, {'name': 'Test'});
        expect(result, equals('Test Test Test'));
      });

      test('replace() handles repeated placeholders', () {
        final stub = '{{ name }} and {{ name }}';
        final result = StubLoader.replace(stub, {'name': 'Alice'});
        expect(result, equals('Alice and Alice'));
      });

      test('replace() leaves unmatched placeholders', () {
        final stub = 'Hello {{ name }} and {{ other }}';
        final result = StubLoader.replace(stub, {'name': 'World'});
        expect(result, equals('Hello World and {{ other }}'));
      });

      test('replace() handles empty replacements map', () {
        final stub = 'Hello {{ name }}!';
        final result = StubLoader.replace(stub, {});
        expect(result, equals('Hello {{ name }}!'));
      });
    });

    group('Case Transformers', () {
      test('toPascalCase() converts snake_case to PascalCase', () {
        expect(StubLoader.toPascalCase('user_profile'), equals('UserProfile'));
        expect(
            StubLoader.toPascalCase('api_controller'), equals('ApiController'));
      });

      test('toPascalCase() handles single word', () {
        expect(StubLoader.toPascalCase('user'), equals('User'));
      });

      test('toSnakeCase() converts PascalCase to snake_case', () {
        expect(StubLoader.toSnakeCase('UserProfile'), equals('user_profile'));
        expect(StubLoader.toSnakeCase('APIController'),
            equals('a_p_i_controller'));
      });

      test('toSnakeCase() handles single word', () {
        expect(StubLoader.toSnakeCase('User'), equals('user'));
      });

      test('toKebabCase() converts PascalCase to kebab-case', () {
        expect(StubLoader.toKebabCase('UserProfile'), equals('user-profile'));
        expect(StubLoader.toKebabCase('APIController'),
            equals('a-p-i-controller'));
      });

      test('toCamelCase() converts snake_case to camelCase', () {
        expect(StubLoader.toCamelCase('user_profile'), equals('userProfile'));
        expect(
            StubLoader.toCamelCase('api_controller'), equals('apiController'));
      });
    });

    group('Integrated make()', () {
      test('make() loads and replaces in one step', () async {
        final stubPath = path.join(tempStubsDir, 'make_test.stub');
        File(stubPath).writeAsStringSync('class {{ className }} {}');

        final result = await StubLoader.make(
          'make_test',
          {'className': 'TestClass'},
          searchPaths: [tempStubsDir],
        );
        expect(result, equals('class TestClass {}'));
      });

      test('makeSync() loads and replaces synchronously', () {
        final stubPath = path.join(tempStubsDir, 'make_test.stub');
        File(stubPath).writeAsStringSync('class {{ className }} {}');

        final result = StubLoader.makeSync(
          'make_test',
          {'className': 'TestClass'},
          searchPaths: [tempStubsDir],
        );
        expect(result, equals('class TestClass {}'));
      });
    });

    group('Multiple Search Paths', () {
      test('searches in multiple directories', () {
        final dir1 = path.join(tempDir.path, 'stubs1');
        final dir2 = path.join(tempDir.path, 'stubs2');
        Directory(dir1).createSync();
        Directory(dir2).createSync();

        File(path.join(dir2, 'test.stub')).writeAsStringSync('Found in dir2');

        final content = StubLoader.loadSync('test', searchPaths: [dir1, dir2]);
        expect(content, equals('Found in dir2'));
      });

      test('prioritizes first directory with matching stub', () {
        final dir1 = path.join(tempDir.path, 'stubs1');
        final dir2 = path.join(tempDir.path, 'stubs2');
        Directory(dir1).createSync();
        Directory(dir2).createSync();

        File(path.join(dir1, 'test.stub')).writeAsStringSync('From dir1');
        File(path.join(dir2, 'test.stub')).writeAsStringSync('From dir2');

        final content = StubLoader.loadSync('test', searchPaths: [dir1, dir2]);
        expect(content, equals('From dir1'));
      });
    });
  });
}
