import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/src/helpers/json_editor.dart';

/// Tests for [JsonEditor] — JSON file manipulation.
///
/// All tests use a temporary directory that is cleaned up after each test.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('magic_test_json_editor');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ---------------------------------------------------------------------------
  // readJson()
  // ---------------------------------------------------------------------------
  group('JsonEditor.readJson()', () {
    test('parses a JSON file into a Map', () {
      final file = File('${tempDir.path}/data.json');
      file.writeAsStringSync('{"name":"Magic","version":"1.0.0"}');

      final result = JsonEditor.readJson(file.path);

      expect(result['name'], equals('Magic'));
      expect(result['version'], equals('1.0.0'));
    });

    test('throws FileSystemException when file does not exist', () {
      expect(
        () => JsonEditor.readJson('${tempDir.path}/missing.json'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws FormatException for malformed JSON', () {
      final file = File('${tempDir.path}/bad.json');
      file.writeAsStringSync('{bad json}');

      expect(
        () => JsonEditor.readJson(file.path),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // writeJson()
  // ---------------------------------------------------------------------------
  group('JsonEditor.writeJson()', () {
    test('writes a map to a JSON file with default 2-space indent', () {
      final filePath = '${tempDir.path}/output.json';
      JsonEditor.writeJson(filePath, {'key': 'value', 'num': 42});

      final content = File(filePath).readAsStringSync();
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      expect(decoded['key'], equals('value'));
      expect(decoded['num'], equals(42));
      // Default indent means the file is pretty-printed
      expect(content, contains('\n'));
    });

    test('respects custom indent parameter', () {
      final filePath = '${tempDir.path}/output4.json';
      JsonEditor.writeJson(filePath, {'a': 1}, indent: 4);

      final content = File(filePath).readAsStringSync();
      // 4-space indent means a key will be preceded by 4 spaces
      expect(content, contains('    "a"'));
    });

    test('creates parent directories if they do not exist', () {
      final filePath = '${tempDir.path}/nested/dir/file.json';
      JsonEditor.writeJson(filePath, {'ok': true});

      expect(File(filePath).existsSync(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // mergeKey()
  // ---------------------------------------------------------------------------
  group('JsonEditor.mergeKey()', () {
    test('adds a new key while preserving existing keys', () {
      final file = File('${tempDir.path}/manifest.json');
      file.writeAsStringSync('{"existing_key":"existing_value"}');

      JsonEditor.mergeKey(file.path, 'new_key', 'new_value');

      final result = JsonEditor.readJson(file.path);
      expect(result['existing_key'], equals('existing_value'));
      expect(result['new_key'], equals('new_value'));
    });

    test('overwrites an existing key with the new value', () {
      final file = File('${tempDir.path}/config.json');
      file.writeAsStringSync('{"version":"1.0"}');

      JsonEditor.mergeKey(file.path, 'version', '2.0');

      final result = JsonEditor.readJson(file.path);
      expect(result['version'], equals('2.0'));
    });

    test('works with non-string values (int, bool, list)', () {
      final file = File('${tempDir.path}/data.json');
      file.writeAsStringSync('{}');

      JsonEditor.mergeKey(file.path, 'count', 42);
      JsonEditor.mergeKey(file.path, 'active', true);
      JsonEditor.mergeKey(file.path, 'tags', ['flutter', 'dart']);

      final result = JsonEditor.readJson(file.path);
      expect(result['count'], equals(42));
      expect(result['active'], isTrue);
      expect(result['tags'], equals(['flutter', 'dart']));
    });

    test('writes valid JSON after merging', () {
      final file = File('${tempDir.path}/manifest.json');
      file.writeAsStringSync('{"gcm_sender_id":"482941778795"}');

      JsonEditor.mergeKey(file.path, 'short_name', 'MyApp');

      final content = file.readAsStringSync();
      // Must be parseable
      expect(() => jsonDecode(content), returnsNormally);
    });
  });

  // ---------------------------------------------------------------------------
  // hasKey()
  // ---------------------------------------------------------------------------
  group('JsonEditor.hasKey()', () {
    test('returns true when the key exists in the JSON file', () {
      final file = File('${tempDir.path}/data.json');
      file.writeAsStringSync('{"gcm_sender_id":"482941778795"}');

      expect(JsonEditor.hasKey(file.path, 'gcm_sender_id'), isTrue);
    });

    test('returns false when the key does not exist', () {
      final file = File('${tempDir.path}/data.json');
      file.writeAsStringSync('{"name":"App"}');

      expect(JsonEditor.hasKey(file.path, 'gcm_sender_id'), isFalse);
    });

    test('returns false for a non-existent file (graceful)', () {
      expect(
        JsonEditor.hasKey('${tempDir.path}/gone.json', 'key'),
        isFalse,
      );
    });
  });
}
