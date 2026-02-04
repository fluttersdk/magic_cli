import 'dart:math';
import 'package:magic_cli/magic_cli.dart';

/// Generate a new application key for the Flutter Magic app.
///
/// This command generates a secure random 32-character string to be used as
/// the APP_KEY. It automatically writes this key to the .env file, creating
/// it if it doesn't exist.
///
/// ## Usage
///
/// ```bash
/// magic key:generate
/// ```
class KeyGenerateCommand extends Command {
  @override
  String get name => 'key:generate';

  @override
  String get description => 'Generate a new application key';

  @override
  Future<void> handle() async {
    final key = _generateRandomKey();
    _writeToEnv(key);

    newLine();
    newLine();
    success('Application key generated successfully!');
    keyValue('APP_KEY', key);
    newLine();

    _checkPubspecAssets();
  }

  /// Write the key to the environment file.
  void _writeToEnv(String key) {
    final envPath = '.env';

    if (FileHelper.fileExists(envPath)) {
      // Read existing .env and update APP_KEY
      final content = FileHelper.readFile(envPath);
      final lines = content.split('\n');
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

      FileHelper.writeFile(envPath, lines.join('\n'));
    } else {
      // Create new .env file
      comment('Creating .env file...');
      FileHelper.writeFile(envPath, 'APP_KEY=$key\n');
    }
  }

  /// Check if .env is included in pubspec.yaml assets.
  void _checkPubspecAssets() {
    if (!FileHelper.fileExists('pubspec.yaml')) return;

    final content = FileHelper.readFile('pubspec.yaml');
    if (!content.contains('- .env')) {
      newLine();
      warn('IMPORTANT: Add .env to your pubspec.yaml assets');
      comment('');
      comment('flutter:');
      comment('  assets:');
      comment('    - .env');
    }
  }

  /// Generate a secure random 32-character key.
  String _generateRandomKey() {
    final random = Random.secure();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(32, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
