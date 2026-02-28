import 'package:args/args.dart';
import 'package:magic_cli/src/console/generator_command.dart';
import 'package:magic_cli/src/console/string_helper.dart';
import 'package:magic_cli/src/helpers/file_helper.dart';
import 'package:magic_cli/src/commands/make_migration_command.dart';
import 'package:magic_cli/src/commands/make_controller_command.dart';
import 'package:magic_cli/src/commands/make_factory_command.dart';
import 'package:magic_cli/src/commands/make_seeder_command.dart';
import 'package:magic_cli/src/commands/make_policy_command.dart';

/// The `magic make:model` generator command.
///
/// Scaffolds a new Eloquent model class using the model stub template.
/// Can optionally generate related classes (migration, controller, factory, seeder, policy)
/// using the corresponding flags.
///
/// ## Usage
///
/// ```bash
/// magic make:model Monitor
/// magic make:model Monitor -mcfsp
/// magic make:model Monitor --all
/// ```
class MakeModelCommand extends GeneratorCommand {
  /// Optional test root override — enables isolation in unit tests.
  final String? _testRoot;

  /// Creates a [MakeModelCommand].
  ///
  /// [testRoot] overrides the project root resolution, used in tests only.
  MakeModelCommand({String? testRoot}) : _testRoot = testRoot;

  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new Eloquent model class';

  @override
  String getDefaultNamespace() => 'lib/app/models';

  @override
  String getProjectRoot() => _testRoot ?? super.getProjectRoot();

  @override
  void configure(ArgParser parser) {
    super.configure(parser);
    parser.addFlag(
      'migration',
      abbr: 'm',
      help: 'Create a new migration file for the model',
      negatable: false,
    );
    parser.addFlag(
      'controller',
      abbr: 'c',
      help: 'Create a new controller for the model',
      negatable: false,
    );
    parser.addFlag(
      'factory',
      abbr: 'f',
      help: 'Create a new factory for the model',
      negatable: false,
    );
    parser.addFlag(
      'seeder',
      abbr: 's',
      help: 'Create a new seeder for the model',
      negatable: false,
    );
    parser.addFlag(
      'policy',
      abbr: 'p',
      help: 'Create a new policy for the model',
      negatable: false,
    );
    parser.addFlag(
      'all',
      abbr: 'a',
      help:
          'Generate a migration, seeder, factory, policy, and resource controller for the model',
      negatable: false,
    );
  }

  @override
  String getStub() => 'model';

  @override
  Map<String, String> getReplacements(String name) {
    final parsed = StringHelper.parseName(name);
    final className = parsed.className;
    final tableName =
        StringHelper.toPlural(StringHelper.toSnakeCase(className));

    return {
      '{{ className }}': className,
      '{{ tableName }}': tableName,
      '{{ resourceName }}': tableName,
      '{{ snakeName }}': StringHelper.toSnakeCase(className),
    };
  }

  @override
  Future<void> handle() async {
    final name = argument(0);
    if (name == null || name.isEmpty) {
      error('Not enough arguments (missing: "name").');
      return;
    }

    // 1. Generate model class
    final filePath = getPath(name);

    if (FileHelper.fileExists(filePath) && !hasOption('force')) {
      error('File already exists at $filePath');
    } else {
      final content = buildClass(name);
      FileHelper.writeFile(filePath, content);
      success('Created: $filePath');
    }

    // 2. Determine if --all was passed
    final doAll = hasOption('all');

    final parsed = StringHelper.parseName(name);
    final className = parsed.className;

    // 3. Generate Migration
    if (doAll || hasOption('migration')) {
      final tableName =
          StringHelper.toPlural(StringHelper.toSnakeCase(className));
      final migCmd = MakeMigrationCommand(testRoot: _testRoot);
      await migCmd
          .runWith(['create_${tableName}_table', '--create=$tableName']);
    }

    // 4. Generate Factory
    if (doAll || hasOption('factory')) {
      final facCmd = MakeFactoryCommand(testRoot: _testRoot);
      await facCmd.runWith([className]);
    }

    // 5. Generate Seeder
    if (doAll || hasOption('seeder')) {
      final seedCmd = MakeSeederCommand(testRoot: _testRoot);
      await seedCmd.runWith([className]);
    }

    // 6. Generate Policy
    if (doAll || hasOption('policy')) {
      final polCmd = MakePolicyCommand(testRoot: _testRoot);
      await polCmd.runWith([className, '--model=$className']);
    }

    // 7. Generate Controller
    if (doAll || hasOption('controller')) {
      final ctrlCmd = MakeControllerCommand(testRoot: _testRoot);
      final args = [className];
      if (doAll) args.add('--resource');
      await ctrlCmd.runWith(args);
    }
  }
}
