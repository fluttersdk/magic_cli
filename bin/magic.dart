import 'package:magic_cli/src/console/kernel.dart';
import 'package:magic_cli/src/commands/key_generate_command.dart';
import 'package:magic_cli/src/commands/make_migration_command.dart';
import 'package:magic_cli/src/commands/make_model_command.dart';
import 'package:magic_cli/src/commands/make_lang_command.dart';
import 'package:magic_cli/src/commands/make_seeder_command.dart';
import 'package:magic_cli/src/commands/make_factory_command.dart';
import 'package:magic_cli/src/commands/make_view_command.dart';
import 'package:magic_cli/src/commands/make_controller_command.dart';
import 'package:magic_cli/src/commands/make_policy_command.dart';

void main(List<String> arguments) async {
  final kernel = Kernel();

  // Register commands
  kernel.register(KeyGenerateCommand());
  kernel.register(MakeMigrationCommand());
  kernel.register(MakeModelCommand());
  kernel.register(MakeViewCommand());
  kernel.register(MakeControllerCommand());
  kernel.register(MakePolicyCommand());
  kernel.register(MakeLangCommand());
  kernel.register(MakeSeederCommand());
  kernel.register(MakeFactoryCommand());


  // Handle arguments
  await kernel.handle(arguments);
}
