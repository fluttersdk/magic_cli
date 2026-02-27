import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../console/command.dart';
import '../helpers/config_editor.dart';
import '../helpers/file_helper.dart';

/// Initialize Magic Framework in an existing Flutter project.
///
/// Creates the recommended directory structure, config files, starter providers,
/// and injects the Magic bootstrap into `main.dart`.
///
/// ## Usage
///
/// ```bash
/// magic install
/// magic install --without-database --without-auth
/// ```
///
/// ## Options
///
/// | Flag | Description |
/// |------|-------------|
/// | `--without-database` | Skip database directories and `config/database.dart` |
/// | `--without-auth` | Skip `config/auth.dart` |
/// | `--without-events` | Skip events setup |
/// | `--without-localization` | Skip `assets/lang/` directory |
/// | `--without-cache` | Skip cache setup |
class InstallCommand extends Command {
  @override
  String get name => 'install';

  @override
  String get description => 'Initialize Magic in a Flutter project';

  /// Injected project root for testing; null means use filesystem detection.
  String? _testRoot;

  /// Return the Flutter project root directory.
  ///
  /// Overridable in tests to point at a temp directory.
  String getProjectRoot() {
    return FileHelper.findProjectRoot();
  }

  @override
  void configure(ArgParser parser) {
    parser.addFlag(
      'without-database',
      help: 'Skip database setup',
      negatable: false,
    );
    parser.addFlag(
      'without-auth',
      help: 'Skip auth setup',
      negatable: false,
    );
    parser.addFlag(
      'without-events',
      help: 'Skip events setup',
      negatable: false,
    );
    parser.addFlag(
      'without-localization',
      help: 'Skip localization setup',
      negatable: false,
    );
    parser.addFlag(
      'without-cache',
      help: 'Skip cache setup',
      negatable: false,
    );
  }

  @override
  Future<void> handle() async {
    final root = getProjectRoot();

    final withoutDatabase = arguments['without-database'] as bool;
    final withoutAuth = arguments['without-auth'] as bool;
    final withoutLocalization = arguments['without-localization'] as bool;

    // 1. Create directory structure based on selected flags.
    _createDirectories(root,
        withoutDatabase: withoutDatabase,
        withoutLocalization: withoutLocalization);

    // 2. Create config files for the chosen feature set.
    _createConfigFiles(root,
        withoutDatabase: withoutDatabase, withoutAuth: withoutAuth);

    // 3. Create starter files — RouteServiceProvider, AppServiceProvider, routes/app.dart.
    _createStarterFiles(root);

    // 4. Inject Magic bootstrap into main.dart (idempotent — checks before inserting).
    _bootstrapMainDart(root);

    success('Magic installed successfully!');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Create the full Magic directory scaffold.
  ///
  /// Skips database directories when [withoutDatabase] is `true`.
  /// Skips `assets/lang` when [withoutLocalization] is `true`.
  void _createDirectories(
    String root, {
    required bool withoutDatabase,
    required bool withoutLocalization,
  }) {
    final appDirs = [
      'lib/app/controllers',
      'lib/app/models',
      'lib/app/enums',
      'lib/app/middleware',
      'lib/app/policies',
      'lib/app/providers',
      'lib/app/listeners',
      'lib/app/events',
      'lib/resources/views',
      'lib/routes',
      'lib/config',
    ];

    for (final dir in appDirs) {
      FileHelper.ensureDirectoryExists(path.join(root, dir));
    }

    if (!withoutDatabase) {
      final dbDirs = [
        'lib/database/migrations',
        'lib/database/seeders',
        'lib/database/factories',
      ];
      for (final dir in dbDirs) {
        FileHelper.ensureDirectoryExists(path.join(root, dir));
      }
    }

    if (!withoutLocalization) {
      FileHelper.ensureDirectoryExists(path.join(root, 'assets/lang'));
    }
  }

  /// Create the config Dart files.
  ///
  /// Always creates `config/app.dart`. Skips `config/auth.dart` when
  /// [withoutAuth] is `true`. Skips `config/database.dart` when
  /// [withoutDatabase] is `true`.
  void _createConfigFiles(
    String root, {
    required bool withoutDatabase,
    required bool withoutAuth,
  }) {
    final appConfigPath = path.join(root, 'lib/config/app.dart');
    if (!FileHelper.fileExists(appConfigPath)) {
      FileHelper.writeFile(appConfigPath, _appConfigContent());
    }

    if (!withoutAuth) {
      final authConfigPath = path.join(root, 'lib/config/auth.dart');
      if (!FileHelper.fileExists(authConfigPath)) {
        FileHelper.writeFile(authConfigPath, _authConfigContent());
      }
    }

    if (!withoutDatabase) {
      final dbConfigPath = path.join(root, 'lib/config/database.dart');
      if (!FileHelper.fileExists(dbConfigPath)) {
        FileHelper.writeFile(dbConfigPath, _databaseConfigContent());
      }
    }
  }

  /// Create the starter provider and route files.
  ///
  /// Files are not overwritten if they already exist.
  void _createStarterFiles(String root) {
    final routeProviderPath =
        path.join(root, 'lib/app/providers/route_service_provider.dart');
    if (!FileHelper.fileExists(routeProviderPath)) {
      FileHelper.writeFile(routeProviderPath, _routeServiceProviderContent());
    }

    final appProviderPath =
        path.join(root, 'lib/app/providers/app_service_provider.dart');
    if (!FileHelper.fileExists(appProviderPath)) {
      FileHelper.writeFile(appProviderPath, _appServiceProviderContent());
    }

    final routesPath = path.join(root, 'lib/routes/app.dart');
    if (!FileHelper.fileExists(routesPath)) {
      FileHelper.writeFile(routesPath, _routesAppContent());
    }
  }

  /// Inject the Magic bootstrap into `main.dart`.
  ///
  /// Idempotent: checks for existing `Magic.init` before inserting to
  /// prevent duplicate bootstrap calls on repeated runs.
  void _bootstrapMainDart(String root) {
    final mainPath = path.join(root, 'lib/main.dart');
    if (!FileHelper.fileExists(mainPath)) {
      return;
    }

    final content = FileHelper.readFile(mainPath);

    // Guard — already bootstrapped, nothing to do.
    if (content.contains('Magic.init')) {
      return;
    }

    // 1. Inject the fluttersdk_magic import if not already present.
    ConfigEditor.addImportToFile(
      filePath: mainPath,
      importStatement:
          "import 'package:fluttersdk_magic/fluttersdk_magic.dart';",
    );

    // 2. Inject the config/app.dart import if not already present.
    ConfigEditor.addImportToFile(
      filePath: mainPath,
      importStatement: "import 'config/app.dart';",
    );

    // 3. Insert Magic.init call before runApp(). The two-space indent matches
    //    the typical Flutter main() body indentation.
    ConfigEditor.insertCodeBeforePattern(
      filePath: mainPath,
      pattern: RegExp(r'runApp\('),
      code:
          '  await Magic.init(\n    configFactories: [() => appConfig],\n  );\n\n  ',
    );
  }

  // ---------------------------------------------------------------------------
  // Content templates
  // ---------------------------------------------------------------------------

  /// Returns the content for `lib/config/app.dart`.
  String _appConfigContent() {
    return '''import 'package:fluttersdk_magic/fluttersdk_magic.dart';

import '../app/providers/app_service_provider.dart';
import '../app/providers/route_service_provider.dart';

/// Application configuration.
Map<String, dynamic> get appConfig => {
  'app': {
    'name': Env.get('APP_NAME', 'My App'),
    'env': Env.get('APP_ENV', 'production'),
    'debug': Env.get('APP_DEBUG', false),
    'key': Env.get('APP_KEY'),
    'providers': [
      (app) => RouteServiceProvider(app),
      (app) => AppServiceProvider(app),
    ],
  },
};
''';
  }

  /// Returns the content for `lib/config/auth.dart`.
  String _authConfigContent() {
    return '''import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// Authentication configuration.
Map<String, dynamic> get authConfig => {
  'auth': {
    'defaults': {
      'guard': 'api',
    },
    'guards': {
      'api': {
        'driver': 'bearer',
      },
    },
    'endpoints': {
      'login': Env.get('AUTH_LOGIN_ENDPOINT', '/auth/login'),
      'logout': Env.get('AUTH_LOGOUT_ENDPOINT', '/auth/logout'),
      'refresh': Env.get('AUTH_REFRESH_ENDPOINT', '/auth/refresh'),
    },
  },
};
''';
  }

  /// Returns the content for `lib/config/database.dart`.
  String _databaseConfigContent() {
    return '''import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// Database configuration.
Map<String, dynamic> get databaseConfig => {
  'database': {
    'default': 'sqlite',
    'connections': {
      'sqlite': {
        'driver': 'sqlite',
        'database': Env.get('DB_DATABASE', 'database.sqlite'),
      },
    },
  },
};
''';
  }

  /// Returns the content for `lib/app/providers/route_service_provider.dart`.
  String _routeServiceProviderContent() {
    return '''import 'package:fluttersdk_magic/fluttersdk_magic.dart';

import '../../routes/app.dart';

/// Route Service Provider — registers all application routes.
class RouteServiceProvider extends ServiceProvider {
  RouteServiceProvider(super.app);

  @override
  void register() {}

  @override
  Future<void> boot() async {
    registerAppRoutes();
  }
}
''';
  }

  /// Returns the content for `lib/app/providers/app_service_provider.dart`.
  String _appServiceProviderContent() {
    return '''import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// App Service Provider — application-level bindings and bootstrapping.
class AppServiceProvider extends ServiceProvider {
  AppServiceProvider(super.app);

  @override
  void register() {}

  @override
  Future<void> boot() async {}
}
''';
  }

  /// Returns the content for `lib/routes/app.dart`.
  String _routesAppContent() {
    return '''import 'package:fluttersdk_magic/fluttersdk_magic.dart';

/// Register application routes.
void registerAppRoutes() {
  // TODO: Define your application routes here.
  // Example:
  // MagicRoute.page('/', () => HomeController.instance.index());
}
''';
  }
}
