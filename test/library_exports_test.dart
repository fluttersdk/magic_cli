import 'package:flutter_test/flutter_test.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';

void main() {
  group('Library Exports', () {
    test('exports Command base class', () {
      // Command should be accessible
      expect(Command, isNotNull);
    });

    test('exports Kernel class', () {
      // Kernel should be accessible
      expect(Kernel, isNotNull);
    });

    test('exports ConsoleStyle helper', () {
      // ConsoleStyle should be accessible after implementation
      expect(() => ConsoleStyle, returnsNormally);
    });

    test('exports FileHelper class', () {
      // FileHelper should be accessible after implementation
      expect(() => FileHelper, returnsNormally);
    });

    test('exports ConfigEditor class', () {
      // ConfigEditor should be accessible after implementation
      expect(() => ConfigEditor, returnsNormally);
    });

    test('exports StubLoader class', () {
      // StubLoader should be accessible after implementation
      expect(() => StubLoader, returnsNormally);
    });
  });
}
