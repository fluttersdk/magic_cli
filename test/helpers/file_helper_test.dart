import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/magic_cli.dart';
import 'package:path/path.dart' as path;

void main() {
  group('FileHelper', () {
    late Directory tempDir;

    setUp(() {
      // Create a temporary directory for each test
      tempDir = Directory.systemTemp.createTempSync('file_helper_test_');
    });

    tearDown(() {
      // Clean up the temporary directory after each test
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('File Existence', () {
      test('fileExists() returns true for existing file', () {
        final testFile = File(path.join(tempDir.path, 'test.txt'));
        testFile.writeAsStringSync('content');

        expect(FileHelper.fileExists(testFile.path), isTrue);
      });

      test('fileExists() returns false for non-existent file', () {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent.txt');
        expect(FileHelper.fileExists(nonExistentPath), isFalse);
      });

      test('directoryExists() returns true for existing directory', () {
        final testDir = Directory(path.join(tempDir.path, 'testdir'));
        testDir.createSync();

        expect(FileHelper.directoryExists(testDir.path), isTrue);
      });

      test('directoryExists() returns false for non-existent directory', () {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent');
        expect(FileHelper.directoryExists(nonExistentPath), isFalse);
      });
    });

    group('File Operations', () {
      test('readFile() returns file content', () {
        final testFile = File(path.join(tempDir.path, 'read_test.txt'));
        testFile.writeAsStringSync('Hello, World!');

        final content = FileHelper.readFile(testFile.path);
        expect(content, equals('Hello, World!'));
      });

      test('readFile() throws on non-existent file', () {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent.txt');
        expect(
          () => FileHelper.readFile(nonExistentPath),
          throwsA(isA<FileSystemException>()),
        );
      });

      test('writeFile() creates and writes content', () {
        final testFile = path.join(tempDir.path, 'write_test.txt');
        FileHelper.writeFile(testFile, 'Test content');

        final file = File(testFile);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Test content'));
      });

      test('writeFile() overwrites existing file', () {
        final testFile = path.join(tempDir.path, 'overwrite.txt');
        File(testFile).writeAsStringSync('old content');

        FileHelper.writeFile(testFile, 'new content');
        expect(File(testFile).readAsStringSync(), equals('new content'));
      });

      test('copyFile() copies file to destination', () {
        final source = path.join(tempDir.path, 'source.txt');
        final dest = path.join(tempDir.path, 'dest.txt');
        File(source).writeAsStringSync('copy me');

        FileHelper.copyFile(source, dest);

        expect(File(dest).existsSync(), isTrue);
        expect(File(dest).readAsStringSync(), equals('copy me'));
      });

      test('deleteFile() removes file', () {
        final testFile = path.join(tempDir.path, 'delete_me.txt');
        File(testFile).writeAsStringSync('delete this');

        FileHelper.deleteFile(testFile);
        expect(File(testFile).existsSync(), isFalse);
      });

      test('deleteFile() does nothing if file does not exist', () {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent.txt');
        // Should not throw
        expect(() => FileHelper.deleteFile(nonExistentPath), returnsNormally);
      });
    });

    group('Directory Operations', () {
      test('ensureDirectoryExists() creates directory if missing', () {
        final newDir = path.join(tempDir.path, 'new_dir');
        FileHelper.ensureDirectoryExists(newDir);

        expect(Directory(newDir).existsSync(), isTrue);
      });

      test('ensureDirectoryExists() creates nested directories', () {
        final nestedDir = path.join(tempDir.path, 'a', 'b', 'c');
        FileHelper.ensureDirectoryExists(nestedDir);

        expect(Directory(nestedDir).existsSync(), isTrue);
      });

      test('ensureDirectoryExists() does nothing if directory exists', () {
        final existingDir = path.join(tempDir.path, 'existing');
        Directory(existingDir).createSync();

        // Should not throw
        expect(
          () => FileHelper.ensureDirectoryExists(existingDir),
          returnsNormally,
        );
      });
    });

    group('YAML Operations', () {
      test('readYamlFile() parses YAML to Map', () {
        final yamlFile = path.join(tempDir.path, 'test.yaml');
        File(yamlFile).writeAsStringSync('''
name: test_package
version: 1.0.0
dependencies:
  args: ^2.7.0
''');

        final data = FileHelper.readYamlFile(yamlFile);
        expect(data, isA<Map<String, dynamic>>());
        expect(data['name'], equals('test_package'));
        expect(data['version'], equals('1.0.0'));
        expect(data['dependencies'], isA<Map>());
      });

      test('readYamlFile() throws on invalid YAML', () {
        final yamlFile = path.join(tempDir.path, 'invalid.yaml');
        File(yamlFile).writeAsStringSync('invalid: yaml: content:');

        expect(
          () => FileHelper.readYamlFile(yamlFile),
          throwsA(isA<Exception>()),
        );
      });

      test('writeYamlFile() writes Map to YAML format', () {
        final yamlFile = path.join(tempDir.path, 'output.yaml');
        final data = {
          'name': 'my_package',
          'version': '2.0.0',
          'dependencies': {'args': '^2.7.0'},
        };

        FileHelper.writeYamlFile(yamlFile, data);

        final file = File(yamlFile);
        expect(file.existsSync(), isTrue);

        final content = file.readAsStringSync();
        expect(content, contains('name: my_package'));
        expect(content, contains('version: 2.0.0'));
      });
    });

    group('Project Root Detection', () {
      test('findProjectRoot() finds directory with pubspec.yaml', () {
        // Create a mock project structure
        final projectRoot = path.join(tempDir.path, 'project');
        final subDir = path.join(projectRoot, 'lib', 'src');
        Directory(subDir).createSync(recursive: true);
        File(path.join(projectRoot, 'pubspec.yaml'))
            .writeAsStringSync('name: test');

        final foundRoot = FileHelper.findProjectRoot(startFrom: subDir);
        expect(foundRoot, equals(projectRoot));
      });

      test('findProjectRoot() throws if no pubspec.yaml found', () {
        final deepDir = path.join(tempDir.path, 'no', 'project', 'here');
        Directory(deepDir).createSync(recursive: true);

        expect(
          () => FileHelper.findProjectRoot(startFrom: deepDir),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Path Operations', () {
      test('getRelativePath() computes relative path', () {
        final from = path.join(tempDir.path, 'a', 'b');
        final to = path.join(tempDir.path, 'a', 'c', 'd.txt');

        final relative = FileHelper.getRelativePath(from, to);
        expect(relative, equals(path.join('..', 'c', 'd.txt')));
      });
    });
  });
}
