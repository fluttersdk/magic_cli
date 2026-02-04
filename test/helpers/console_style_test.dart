import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/magic_cli.dart';

void main() {
  group('ConsoleStyle', () {
    group('Output Formatting', () {
      test('success() returns green checkmark message', () {
        final result = ConsoleStyle.success('Operation completed');
        expect(result, contains('Operation completed'));
        expect(result, contains('\x1B[32m')); // Green color code
        expect(result, contains('\x1B[0m')); // Reset code
      });

      test('error() returns red X message', () {
        final result = ConsoleStyle.error('Operation failed');
        expect(result, contains('Operation failed'));
        expect(result, contains('\x1B[31m')); // Red color code
        expect(result, contains('\x1B[0m')); // Reset code
      });

      test('info() returns blue info message', () {
        final result = ConsoleStyle.info('Information');
        expect(result, contains('Information'));
        expect(result, contains('\x1B[34m')); // Blue color code
        expect(result, contains('\x1B[0m')); // Reset code
      });

      test('warning() returns yellow warning message', () {
        final result = ConsoleStyle.warning('Warning message');
        expect(result, contains('Warning message'));
        expect(result, contains('\x1B[33m')); // Yellow color code
        expect(result, contains('\x1B[0m')); // Reset code
      });

      test('comment() returns dimmed message', () {
        final result = ConsoleStyle.comment('Comment text');
        expect(result, contains('Comment text'));
        expect(result, contains('\x1B[2m')); // Dim code
        expect(result, contains('\x1B[0m')); // Reset code
      });

      test('step() returns progress counter', () {
        final result = ConsoleStyle.step(3, 5, 'Installing packages');
        expect(result, contains('3'));
        expect(result, contains('5'));
        expect(result, contains('Installing packages'));
      });
    });

    group('Layout', () {
      test('line() returns horizontal rule with default char', () {
        final result = ConsoleStyle.line();
        expect(result, contains('─'));
        expect(result.length, greaterThan(10));
      });

      test('line() accepts custom char and length', () {
        final result = ConsoleStyle.line(char: '=', length: 20);
        expect(result, equals('=' * 20));
      });

      test('newLine() returns empty line', () {
        final result = ConsoleStyle.newLine();
        expect(result, equals(''));
      });

      test('header() returns formatted section header', () {
        final result = ConsoleStyle.header('Configuration');
        expect(result, contains('Configuration'));
        expect(result, contains('\x1B[1m')); // Bold code
      });

      test('banner() returns customizable package banner', () {
        final result = ConsoleStyle.banner('Magic CLI', '1.0.0');
        expect(result, contains('Magic CLI'));
        expect(result, contains('1.0.0'));
      });
    });

    group('Data Display', () {
      test('table() formats headers and rows', () {
        final result = ConsoleStyle.table(
          ['Name', 'Status'],
          [
            ['User', 'Active'],
            ['Admin', 'Inactive'],
          ],
        );
        expect(result, contains('Name'));
        expect(result, contains('Status'));
        expect(result, contains('User'));
        expect(result, contains('Admin'));
      });

      test('keyValue() formats aligned key-value pair', () {
        final result = ConsoleStyle.keyValue('Name', 'John Doe');
        expect(result, contains('Name'));
        expect(result, contains('John Doe'));
      });

      test('keyValue() accepts custom key width', () {
        final result = ConsoleStyle.keyValue('Key', 'Value', keyWidth: 30);
        expect(result, contains('Key'));
        expect(result, contains('Value'));
      });
    });

    group('ANSI Color Codes', () {
      test('green constant is defined', () {
        expect(ConsoleStyle.green, equals('\x1B[32m'));
      });

      test('red constant is defined', () {
        expect(ConsoleStyle.red, equals('\x1B[31m'));
      });

      test('yellow constant is defined', () {
        expect(ConsoleStyle.yellow, equals('\x1B[33m'));
      });

      test('blue constant is defined', () {
        expect(ConsoleStyle.blue, equals('\x1B[34m'));
      });

      test('cyan constant is defined', () {
        expect(ConsoleStyle.cyan, equals('\x1B[36m'));
      });

      test('magenta constant is defined', () {
        expect(ConsoleStyle.magenta, equals('\x1B[35m'));
      });

      test('white constant is defined', () {
        expect(ConsoleStyle.white, equals('\x1B[37m'));
      });

      test('bold constant is defined', () {
        expect(ConsoleStyle.bold, equals('\x1B[1m'));
      });

      test('dim constant is defined', () {
        expect(ConsoleStyle.dim, equals('\x1B[2m'));
      });

      test('reset constant is defined', () {
        expect(ConsoleStyle.reset, equals('\x1B[0m'));
      });
    });
  });
}
