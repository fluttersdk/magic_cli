import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import '../console/command.dart';
import '../helpers/file_helper.dart';

/// Generate a new application key for the Flutter Magic app.
class KeyGenerateCommand extends Command {
  @override
  String get name => 'key:generate';

  @override
  String get description => 'Generate a new application key';

  @override
  void configure(ArgParser parser) {
    parser.addFlag(
      'show',
      help: 'Display the key instead of modifying the .env file',
      negatable: false,
    );
  }

  @override
  Future<void> handle() async {
    // 1. Generate a random 32-byte key and base64 encode it.
    final key = _generateKey();
    final keyWithPrefix = 'base64:$key';

    // 2. If --show flag is present, only output the key.
    if (hasOption('show')) {
      info('APP_KEY=$keyWithPrefix');
      return;
    }

    // 3. Find project root and target .env file.
    final root = FileHelper.findProjectRoot();
    final envFile = File('$root/.env');

    // 4. Update or create .env file with the new key.
    _writeToEnv(envFile, keyWithPrefix);

    // 5. Output success message.
    success('Application key set successfully.');
    keyValue('APP_KEY', keyWithPrefix);
  }

  /// Write the key to the environment file.
  void _writeToEnv(File envFile, String key) {
    if (envFile.existsSync()) {
      final content = envFile.readAsStringSync();
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

      envFile.writeAsStringSync(lines.join('\n'));
    } else {
      envFile.writeAsStringSync('APP_KEY=$key\n');
    }
  }

  /// Generate a secure random 32-byte key base64 encoded.
  String _generateKey() {
    final bytes = List.generate(32, (_) => Random.secure().nextInt(256));
    return base64.encode(bytes);
  }
}
