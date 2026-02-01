import 'package:args/args.dart';
import 'package:fluttersdk_magic_cli/src/console/command.dart';
import 'package:fluttersdk_magic_cli/src/boost/guideline_generator.dart';
import 'dart:io';

/// The Boost Update Command.
///
/// Refreshes AI guidelines from the latest templates.
///
/// Usage:
/// ```bash
/// magic boost:update
/// ```
class BoostUpdateCommand extends Command {
  @override
  String get name => 'boost:update';

  @override
  String get description => 'Update Magic Boost guidelines to latest version';

  @override
  void configure(ArgParser parser) {
    // No additional arguments
  }

  @override
  Future<void> handle() async {
    info('🔄 Updating Magic Boost guidelines...');
    info('');

    final generator = GuidelineGenerator(Directory.current.path);
    await generator.generate();

    info('  \x1B[32m✓\x1B[0m Updated .magic/guidelines/core.md');
    info('  \x1B[32m✓\x1B[0m Updated .magic/guidelines/wind.md');
    info('  \x1B[32m✓\x1B[0m Updated .magic/guidelines/eloquent.md');
    info('  \x1B[32m✓\x1B[0m Updated .magic/guidelines/routing.md');
    info('');
    info('\x1B[32m✓\x1B[0m Guidelines updated successfully!');
  }
}
