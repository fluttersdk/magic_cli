import 'package:fluttersdk_magic_cli/src/console/kernel.dart';
import 'package:fluttersdk_magic_cli/src/commands/key_generate_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_migration_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_model_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_lang_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_seeder_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_factory_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_model_types_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_view_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_controller_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/make_policy_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/route_list_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/config_list_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/config_get_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/boost_install_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/boost_mcp_command.dart';
import 'package:fluttersdk_magic_cli/src/commands/boost_update_command.dart';

void main(List<String> arguments) async {
  final kernel = Kernel();

  // Register commands
  kernel.register(KeyGenerateCommand());
  kernel.register(MakeMigrationCommand());
  kernel.register(MakeModelCommand());
  kernel.register(MakeModelTypesCommand());
  kernel.register(MakeViewCommand());
  kernel.register(MakeControllerCommand());
  kernel.register(MakePolicyCommand());
  kernel.register(MakeLangCommand());
  kernel.register(MakeSeederCommand());
  kernel.register(MakeFactoryCommand());
  kernel.register(RouteListCommand());
  kernel.register(ConfigListCommand());
  kernel.register(ConfigGetCommand());

  // Boost commands
  kernel.register(BoostInstallCommand());
  kernel.register(BoostMcpCommand());
  kernel.register(BoostUpdateCommand());

  // Handle arguments
  await kernel.handle(arguments);
}
