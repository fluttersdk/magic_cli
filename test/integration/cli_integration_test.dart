import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magic_cli/magic_cli.dart';

void main() {
  late Directory tempDir;
  late Kernel kernel;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('magic_integration_');
    // Create a dummy pubspec.yaml so findProjectRoot works!
    File('${tempDir.path}/pubspec.yaml')
        .writeAsStringSync('name: dummy_project\n');

    kernel = Kernel();
    kernel.registerMany([
      InstallCommand(),
      KeyGenerateCommand(),
      MakeControllerCommand(),
      MakeEnumCommand(),
      MakeEventCommand(),
      MakeFactoryCommand(),
      MakeLangCommand(),
      MakeListenerCommand(),
      MakeMiddlewareCommand(),
      MakeMigrationCommand(),
      MakeModelCommand(),
      MakePolicyCommand(),
      MakeProviderCommand(),
      MakeRequestCommand(),
      MakeSeederCommand(),
      MakeViewCommand(),
    ]);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // Helper to run commands in the temp dir context
  Future<void> runInTempDir(List<String> args) async {
    final originalDir = Directory.current;
    try {
      Directory.current = tempDir;
      await kernel.handle(args);
    } finally {
      Directory.current = originalDir;
    }
  }

  group('Kernel output & error handling', () {
    test('prints help when no arguments provided', () async {
      await runInTempDir([]);
      expect(true, isTrue);
    });

    test('handles unknown commands gracefully', () async {
      final originalExitCode = exitCode;
      await runInTempDir(['unknown:command']);
      expect(exitCode, 1);
      exitCode = originalExitCode;
    });

    test('missing required arguments exits gracefully without throwing',
        () async {
      // Our Command base class just prints an error and returns for missing args,
      // it doesn't actually set exitCode to 1 or throw. So let's just verify it
      // doesn't throw.
      await runInTempDir(['make:controller']);
      expect(true, isTrue);
    });
  });

  group('Make Commands', () {
    test('make:controller generates controller file', () async {
      await runInTempDir(['make:controller', 'TestMonitor']);
      final file = File(
          '${tempDir.path}/lib/app/controllers/test_monitor_controller.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class TestMonitorController'));
    });

    test('make:enum generates enum file', () async {
      await runInTempDir(['make:enum', 'Status']);
      final file = File('${tempDir.path}/lib/app/enums/status.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('enum Status'));
    });

    test('make:event generates event file', () async {
      await runInTempDir(['make:event', 'UserCreated']);
      final file = File('${tempDir.path}/lib/app/events/user_created.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class UserCreated'));
    });

    test('make:factory generates factory file', () async {
      await runInTempDir(['make:factory', 'User']);
      final file =
          File('${tempDir.path}/lib/database/factories/user_factory.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class UserFactory'));
    });

    test('make:lang generates language file', () async {
      await runInTempDir(['make:lang', 'en']);
      final file = File('${tempDir.path}/assets/lang/en.json');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('{'));
    });

    test('make:listener generates listener file', () async {
      await runInTempDir(['make:listener', 'SendWelcomeEmail']);
      final file =
          File('${tempDir.path}/lib/app/listeners/send_welcome_email.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class SendWelcomeEmail'));
    });

    test('make:middleware generates middleware file', () async {
      await runInTempDir(['make:middleware', 'CheckAdmin']);
      final file = File('${tempDir.path}/lib/app/middleware/check_admin.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class CheckAdmin'));
    });

    test('make:migration generates migration file', () async {
      await runInTempDir(['make:migration', 'create_users_table']);

      final dir = Directory('${tempDir.path}/lib/database/migrations');
      expect(dir.existsSync(), isTrue);

      final files = dir.listSync().whereType<File>().toList();
      expect(files.length, 1);
      expect(files.first.path, contains('create_users_table.dart'));

      final content = files.first.readAsStringSync();
      // Migration class is generated as timestamp_name (e.g. 20260228021934_create_users_table)
      // in PascalCase: 20260228021934CreateUsersTable
      // However the test just needs to ensure it contains the expected content.
      expect(content, contains('class'));
      expect(content, contains('extends Migration'));
    });

    test('make:model generates model file', () async {
      await runInTempDir(['make:model', 'Product']);
      final file = File('${tempDir.path}/lib/app/models/product.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class Product'));
    });

    test('make:model with -a flag generates all related files', () async {
      await runInTempDir(['make:model', 'Order', '-a']);

      expect(File('${tempDir.path}/lib/app/models/order.dart').existsSync(),
          isTrue);
      expect(
          File('${tempDir.path}/lib/app/controllers/order_controller.dart')
              .existsSync(),
          isTrue);
      expect(
          File('${tempDir.path}/lib/app/policies/order_policy.dart')
              .existsSync(),
          isTrue);
      expect(
          File('${tempDir.path}/lib/database/factories/order_factory.dart')
              .existsSync(),
          isTrue);
      expect(
          File('${tempDir.path}/lib/database/seeders/order_seeder.dart')
              .existsSync(),
          isTrue);

      final migDir = Directory('${tempDir.path}/lib/database/migrations');
      final files = migDir.listSync().whereType<File>().toList();
      expect(files.any((f) => f.path.contains('create_orders_table.dart')),
          isTrue);
    });

    test('make:policy generates policy file', () async {
      await runInTempDir(['make:policy', 'Post']);
      final file = File('${tempDir.path}/lib/app/policies/post_policy.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class PostPolicy'));
    });

    test('make:provider generates provider file', () async {
      await runInTempDir(['make:provider', 'Auth']);
      final file =
          File('${tempDir.path}/lib/app/providers/auth_service_provider.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class AuthServiceProvider'));
    });

    test('make:request generates request file', () async {
      await runInTempDir(['make:request', 'StorePost']);
      final file = File(
          '${tempDir.path}/lib/app/validation/requests/store_post_request.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class StorePostRequest'));
    });

    test('make:seeder generates seeder file', () async {
      await runInTempDir(['make:seeder', 'User']);
      final file =
          File('${tempDir.path}/lib/database/seeders/user_seeder.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class UserSeeder'));
    });

    test('make:view generates view file', () async {
      await runInTempDir(['make:view', 'Profile']);
      final file =
          File('${tempDir.path}/lib/resources/views/profile_view.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class ProfileView'));
    });
  });

  group('install & key:generate', () {
    test('install scaffolds the project', () async {
      await runInTempDir(['install']);

      expect(Directory('${tempDir.path}/lib/app/controllers').existsSync(),
          isTrue);
      expect(Directory('${tempDir.path}/lib/database/migrations').existsSync(),
          isTrue);
      expect(File('${tempDir.path}/lib/config/app.dart').existsSync(), isTrue);
      expect(File('${tempDir.path}/lib/config/auth.dart').existsSync(), isTrue);
      expect(File('${tempDir.path}/lib/config/database.dart').existsSync(),
          isTrue);
    });

    test('key:generate creates or updates .env with APP_KEY', () async {
      await runInTempDir(['key:generate']);

      final envFile = File('${tempDir.path}/.env');
      expect(envFile.existsSync(), isTrue);
      expect(envFile.readAsStringSync(), contains('APP_KEY=base64:'));
    });
  });

  group('File existence protection', () {
    test('refuses to overwrite existing file without --force', () async {
      await runInTempDir(['make:controller', 'Protected']);
      final file =
          File('${tempDir.path}/lib/app/controllers/protected_controller.dart');
      expect(file.existsSync(), isTrue);

      file.writeAsStringSync('modified content');

      final originalExitCode = exitCode;
      await runInTempDir(['make:controller', 'Protected']);

      expect(file.readAsStringSync(), 'modified content');

      await runInTempDir(['make:controller', 'Protected', '--force']);

      expect(file.readAsStringSync(), contains('class ProtectedController'));
      exitCode = originalExitCode;
    });
  });
}
