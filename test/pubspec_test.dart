import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('pubspec.yaml', () {
    test('has required CLI dependencies', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue,
          reason: 'pubspec.yaml must exist');

      final pubspecContent = pubspecFile.readAsStringSync();
      final yaml = loadYaml(pubspecContent) as Map;

      final dependencies = yaml['dependencies'] as Map?;
      expect(dependencies, isNotNull,
          reason: 'dependencies section must exist');

      // Required dependencies
      expect(dependencies!.containsKey('args'), isTrue,
          reason: 'args package is required for command-line parsing');
      expect(dependencies.containsKey('path'), isTrue,
          reason: 'path package is required for file path handling');
      expect(dependencies.containsKey('yaml'), isTrue,
          reason: 'yaml package is required for YAML file reading');
      expect(dependencies.containsKey('yaml_edit'), isTrue,
          reason: 'yaml_edit package is required for safe YAML editing');

      // Verify versions are properly specified
      expect(dependencies['args'].toString(), startsWith('^2.'),
          reason: 'args should use compatible version ^2.x');
      expect(dependencies['path'].toString(), startsWith('^1.'),
          reason: 'path should use compatible version ^1.x');
      expect(dependencies['yaml'].toString(), startsWith('^3.'),
          reason: 'yaml should use compatible version ^3.x');
      expect(dependencies['yaml_edit'].toString(), startsWith('^2.'),
          reason: 'yaml_edit should use compatible version ^2.x');
    });
  });
}
