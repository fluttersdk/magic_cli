import 'dart:io';
import 'dart:math';
import 'package:fluttersdk_magic_cli/src/console/command.dart';

/// The Key Generate Command.
///
/// This command generates a secure random 32-character string to be used as
/// the [APP_KEY]. It attempts to automatically write this key to the [.env] file
/// if it exists, or creates one if it does not.
class KeyGenerateCommand extends Command {
  @override
  String get name => 'key:generate';

  @override
  String get description => 'Set the application key';

  /// Execute the console command.
  @override
  Future<void> handle() async {
    final key = generateRandomKey();
    _writeToEnv(key);

    info('Application Key set successfully.');
    info('APP_KEY=$key');
  }

  /// Write the key to the environment file.
  void _writeToEnv(String key) {
    final file = File('.env');
    List<String> lines = [];

    if (file.existsSync()) {
      lines = file.readAsLinesSync();
    } else {
      comment('Creating .env file...');
      file.createSync();
    }

    bool keyExists = false;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('APP_KEY=')) {
        lines[i] = 'APP_KEY=$key';
        keyExists = true;
        break;
      }
    }

    if (!keyExists) {
      if (lines.isNotEmpty && lines.last.isNotEmpty) {
        lines.add('');
      }
      lines.add('APP_KEY=$key');
    }

    file.writeAsStringSync(lines.join('\n'));

    // Check if .env is in pubspec
    _checkPubspec();
  }

  void _checkPubspec() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return;

    final content = pubspec.readAsStringSync();
    if (!content.contains('- .env')) {
      comment('IMPORTANT: Make sure to add this to your pubspec.yaml:');
      comment('flutter:');
      comment('  assets:');
      comment('    - .env');
    }
  }

  /// Generate a secure random key.
  String generateRandomKey() {
    final random = Random.secure();

    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(32, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
