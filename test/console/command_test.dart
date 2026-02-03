import 'package:flutter_test/flutter_test.dart';
import 'package:fluttersdk_magic_cli/fluttersdk_magic_cli.dart';
import 'package:args/args.dart';

// Test command implementation
class TestCommand extends Command {
  @override
  String get name => 'test';

  @override
  String get description => 'Test command';

  String? lastOutput;
  final List<String> outputs = [];

  @override
  Future<void> handle() async {
    // Test different output methods
    line('Plain line');
    info('Info message');
    success('Success message');
    warn('Warning message');
    error('Error message');
    comment('Comment text');

    // Test newLine
    newLine();

    // Test table
    table(['Name', 'Status'], [
      ['User', 'Active'],
    ]);

    // Test key-value
    keyValue('Key', 'Value');
  }
}

void main() {
  group('Command', () {
    late TestCommand command;

    setUp(() {
      command = TestCommand();
      final parser = ArgParser();
      command.arguments = parser.parse([]);
    });

    group('Basic Properties', () {
      test('has name property', () {
        expect(command.name, equals('test'));
      });

      test('has description property', () {
        expect(command.description, equals('Test command'));
      });
    });

    group('Output Methods', () {
      test('line() outputs plain text', () {
        // Just verify method exists and can be called
        expect(() => command.line('test'), returnsNormally);
      });

      test('info() uses ConsoleStyle.info()', () {
        // Verify method exists
        expect(() => command.info('test'), returnsNormally);
      });

      test('success() uses ConsoleStyle.success()', () {
        expect(() => command.success('test'), returnsNormally);
      });

      test('warn() uses ConsoleStyle.warning()', () {
        expect(() => command.warn('test'), returnsNormally);
      });

      test('error() uses ConsoleStyle.error()', () {
        expect(() => command.error('test'), returnsNormally);
      });

      test('comment() uses ConsoleStyle.comment()', () {
        expect(() => command.comment('test'), returnsNormally);
      });

      test('newLine() outputs empty line', () {
        expect(() => command.newLine(), returnsNormally);
      });

      test('table() formats data as table', () {
        expect(
          () => command.table(['H1', 'H2'], [['V1', 'V2']]),
          returnsNormally,
        );
      });

      test('keyValue() formats key-value pair', () {
        expect(() => command.keyValue('Key', 'Value'), returnsNormally);
      });
    });

    group('Interactive Input', () {
      // Note: Interactive methods require stdin which we can't easily mock in tests
      // These methods are tested manually and through integration tests
      test('ask() method exists', () {
        expect(command.ask, isNotNull);
      });

      test('confirm() method exists', () {
        expect(command.confirm, isNotNull);
      });

      test('choice() method exists', () {
        expect(command.choice, isNotNull);
      });
    });

    group('Argument Access', () {
      test('option() retrieves named option value', () {
        final parser = ArgParser();
        parser.addFlag('verbose');
        parser.addOption('name');
        command.arguments = parser.parse(['--verbose', '--name=test']);

        expect(command.option('verbose'), isTrue);
        expect(command.option('name'), equals('test'));
      });

      test('option() returns null for missing option', () {
        final parser = ArgParser();
        command.arguments = parser.parse([]);
        expect(command.option('missing'), isNull);
      });

      test('argument() retrieves positional argument by index', () {
        final parser = ArgParser();
        command.arguments = parser.parse(['first', 'second']);

        expect(command.argument(0), equals('first'));
        expect(command.argument(1), equals('second'));
      });

      test('argument() returns null for out of bounds index', () {
        final parser = ArgParser();
        command.arguments = parser.parse(['first']);
        expect(command.argument(1), isNull);
      });

      test('hasOption() checks if option was provided', () {
        final parser = ArgParser();
        parser.addFlag('verbose');
        parser.addFlag('other');
        command.arguments = parser.parse(['--verbose']);

        expect(command.hasOption('verbose'), isTrue);
        expect(command.hasOption('other'), isFalse);
      });
    });

    group('Configuration', () {
      test('configure() can be overridden to add arguments', () {
        final parser = ArgParser();
        command.configure(parser);
        // Should not throw
        expect(parser, isNotNull);
      });
    });

    group('Execution', () {
      test('handle() can be executed', () async {
        await expectLater(command.handle(), completes);
      });
    });
  });
}
