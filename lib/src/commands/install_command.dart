import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../console/command.dart';
import '../helpers/file_helper.dart';
import '../stubs/install_stubs.dart';

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
/// | `--without-network` | Skip `config/network.dart` |
/// | `--without-cache` | Skip `config/cache.dart` |
/// | `--without-events` | Skip events setup |
/// | `--without-localization` | Skip `assets/lang/` directory |
/// | `--without-logging` | Skip `config/logging.dart` |
class InstallCommand extends Command {
  @override
  String get name => 'install';

  @override
  String get description => 'Initialize Magic in a Flutter project';

  /// Return the Flutter project root directory.
  ///
  /// Overridable in tests to point at a temp directory.
  String getProjectRoot() {
    return FileHelper.findProjectRoot();
  }

  @override
  void configure(ArgParser parser) {
    parser.addFlag(
      'without-auth',
      help: 'Skip auth setup',
      negatable: false,
    );
    parser.addFlag(
      'without-database',
      help: 'Skip database setup',
      negatable: false,
    );
    parser.addFlag(
      'without-network',
      help: 'Skip network setup',
      negatable: false,
    );
    parser.addFlag(
      'without-cache',
      help: 'Skip cache setup',
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
      'without-logging',
      help: 'Skip logging setup',
      negatable: false,
    );
  }

  @override
  Future<void> handle() async {
    final root = getProjectRoot();

    final withoutAuth = arguments['without-auth'] as bool;
    final withoutDatabase = arguments['without-database'] as bool;
    final withoutNetwork = arguments['without-network'] as bool;
    final withoutCache = arguments['without-cache'] as bool;
    final withoutEvents = arguments['without-events'] as bool;
    final withoutLocalization = arguments['without-localization'] as bool;
    final withoutLogging = arguments['without-logging'] as bool;

    _createDirectories(
      root,
      withoutDatabase: withoutDatabase,
      withoutEvents: withoutEvents,
      withoutLocalization: withoutLocalization,
    );

    _createConfigFiles(
      root,
      withoutAuth: withoutAuth,
      withoutDatabase: withoutDatabase,
      withoutNetwork: withoutNetwork,
      withoutCache: withoutCache,
      withoutLogging: withoutLogging,
      withoutLocalization: withoutLocalization,
    );

    _createStarterFiles(root);

    _createMainDart(
      root,
      withoutAuth: withoutAuth,
      withoutDatabase: withoutDatabase,
      withoutNetwork: withoutNetwork,
      withoutCache: withoutCache,
      withoutLogging: withoutLogging,
    );

    _createEnvFiles(root);

    _registerEnvAsset(root);

    if (!withoutDatabase) {
      await _setupWebSupport(root);
    }

    success('Magic installed successfully!');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Creates all required directories under [root].  Skips optional dirs when
  /// the corresponding feature flag is disabled.
  ///
  /// [root] — absolute path to the Flutter project root.
  /// [withoutDatabase] — when `true`, skips `lib/database/` tree.
  /// [withoutEvents] — when `true`, skips `lib/app/events` and `lib/app/listeners`.
  /// [withoutLocalization] — when `true`, skips `assets/lang/`.
  void _createDirectories(
    String root, {
    required bool withoutDatabase,
    required bool withoutEvents,
    required bool withoutLocalization,
  }) {
    final appDirs = [
      'lib/app/controllers',
      'lib/app/models',
      'lib/app/enums',
      'lib/app/middleware',
      'lib/app/policies',
      'lib/app/providers',
      'lib/resources/views',
      'lib/routes',
      'lib/config',
    ];

    if (!withoutEvents) {
      appDirs.addAll([
        'lib/app/listeners',
        'lib/app/events',
      ]);
    }

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

  /// Writes all config files under `lib/config/`.  Optional configs are skipped
  /// based on the active feature flags.
  ///
  /// Always writes `app.dart` and `view.dart` regardless of flags.
  /// Builds the dynamic `providerImports` and `providerEntries` lists so that
  /// `app.dart` lists exactly the providers needed for the enabled features.
  ///
  /// [root] — absolute path to the Flutter project root.
  void _createConfigFiles(
    String root, {
    required bool withoutAuth,
    required bool withoutDatabase,
    required bool withoutNetwork,
    required bool withoutCache,
    required bool withoutLogging,
    required bool withoutLocalization,
  }) {
    final providerImports = <String>[];
    final providerEntries = <String>[];
    final authProviderEntries = <String>[];

    // Infrastructure providers — order matters:
    // 1. Cache, Database, Network, Vault must boot before Auth.
    // 2. AppServiceProvider registers userFactory (setUserFactory),
    //    so it MUST boot before AuthServiceProvider.
    // 3. AuthServiceProvider calls Auth.restore() which needs the
    //    user factory and network driver to be ready.
    if (!withoutCache) {
      providerEntries.add('(app) => CacheServiceProvider(app),');
    }
    if (!withoutDatabase) {
      providerEntries.add('(app) => DatabaseServiceProvider(app),');
    }

    // Launch is always registered — the welcome view uses Launch.url().
    providerEntries.add('(app) => LaunchServiceProvider(app),');

    if (!withoutLocalization) {
      providerEntries.add('(app) => LocalizationServiceProvider(app),');
    }
    if (!withoutNetwork) {
      providerEntries.add('(app) => NetworkServiceProvider(app),');
    }
    if (!withoutAuth) {
      providerEntries.add('(app) => VaultServiceProvider(app),');
    }

    // Auth providers boot AFTER AppServiceProvider (which registers
    // userFactory via setUserFactory). AuthServiceProvider.boot()
    // calls Auth.restore() which requires the factory.
    if (!withoutAuth) {
      authProviderEntries.add('(app) => AuthServiceProvider(app),');
    }

    _writeIfNotExists(
      path.join(root, 'lib/config/app.dart'),
      InstallStubs.appConfigContent(
        providerImports: providerImports,
        providerEntries: providerEntries,
        authProviderEntries: authProviderEntries,
      ),
    );

    _writeIfNotExists(
      path.join(root, 'lib/config/view.dart'),
      InstallStubs.viewConfigContent(),
    );

    if (!withoutAuth) {
      _writeIfNotExists(
        path.join(root, 'lib/config/auth.dart'),
        InstallStubs.authConfigContent(),
      );
    }
    if (!withoutDatabase) {
      _writeIfNotExists(
        path.join(root, 'lib/config/database.dart'),
        InstallStubs.databaseConfigContent(),
      );
    }
    if (!withoutNetwork) {
      _writeIfNotExists(
        path.join(root, 'lib/config/network.dart'),
        InstallStubs.networkConfigContent(),
      );
    }
    if (!withoutCache) {
      _writeIfNotExists(
        path.join(root, 'lib/config/cache.dart'),
        InstallStubs.cacheConfigContent(),
      );
    }
    if (!withoutLogging) {
      _writeIfNotExists(
        path.join(root, 'lib/config/logging.dart'),
        InstallStubs.loggingConfigContent(),
      );
    }
  }

  /// Writes the framework starter files that are always created:
  /// `RouteServiceProvider`, `AppServiceProvider`, `kernel.dart`,
  /// `routes/app.dart`, and `resources/views/welcome_view.dart`.
  ///
  /// [root] — absolute path to the Flutter project root.
  void _createStarterFiles(String root) {
    _writeIfNotExists(
      path.join(root, 'lib/app/providers/route_service_provider.dart'),
      InstallStubs.routeServiceProviderContent(),
    );

    _writeIfNotExists(
      path.join(root, 'lib/app/providers/app_service_provider.dart'),
      InstallStubs.appServiceProviderContent(),
    );

    _writeIfNotExists(
      path.join(root, 'lib/app/kernel.dart'),
      InstallStubs.kernelDartContent(),
    );

    final appName = _getAppName(root);

    _writeIfNotExists(
      path.join(root, 'lib/routes/app.dart'),
      InstallStubs.routesAppContent(appName: appName),
    );

    _writeIfNotExists(
      path.join(root, 'lib/resources/views/welcome_view.dart'),
      InstallStubs.welcomeViewContent(appName: appName),
    );
  }

  /// Writes `lib/main.dart` with Magic bootstrap.
  ///
  /// Performs an idempotency check first — if `Magic.init` is already present,
  /// the file is left unchanged to preserve customisations.
  /// Builds dynamic `configImports` and `configFactories` lists based on flags,
  /// then delegates rendering to [InstallStubs.mainDartContent].
  ///
  /// [root] — absolute path to the Flutter project root.
  void _createMainDart(
    String root, {
    required bool withoutAuth,
    required bool withoutDatabase,
    required bool withoutNetwork,
    required bool withoutCache,
    required bool withoutLogging,
  }) {
    final mainPath = path.join(root, 'lib/main.dart');

    if (FileHelper.fileExists(mainPath)) {
      final existing = FileHelper.readFile(mainPath);
      if (existing.contains('Magic.init')) {
        // Idempotency: Magic.init already present — preserve existing bootstrap.
        return;
      }
    }

    final configImports = <String>[
      "import 'config/app.dart';",
      "import 'config/view.dart';",
    ];

    final configFactories = <String>[
      '() => appConfig',
      '() => viewConfig',
    ];

    if (!withoutAuth) {
      configImports.add("import 'config/auth.dart';");
      configFactories.add('() => authConfig');
    }
    if (!withoutDatabase) {
      configImports.add("import 'config/database.dart';");
      configFactories.add('() => databaseConfig');
    }
    if (!withoutNetwork) {
      configImports.add("import 'config/network.dart';");
      configFactories.add('() => networkConfig');
    }
    if (!withoutCache) {
      configImports.add("import 'config/cache.dart';");
      configFactories.add('() => cacheConfig');
    }
    if (!withoutLogging) {
      configImports.add("import 'config/logging.dart';");
      configFactories.add('() => loggingConfig');
    }

    final appName = _getAppName(root);

    FileHelper.writeFile(
      mainPath,
      InstallStubs.mainDartContent(
        appName: appName,
        configImports: configImports,
        configFactories: configFactories,
      ),
    );
  }

  /// Writes `.env` and `.env.example` to [root] if they do not already exist.
  ///
  /// [root] — absolute path to the Flutter project root.
  void _createEnvFiles(String root) {
    final appName = _getAppName(root);

    _writeIfNotExists(
      path.join(root, '.env'),
      InstallStubs.envContent(appName: appName),
    );

    _writeIfNotExists(
      path.join(root, '.env.example'),
      InstallStubs.envExampleContent(),
    );
  }

  /// Reads the `name` field from `pubspec.yaml` and converts it to Title Case.
  ///
  /// For example `magic_e2e_test` → `Magic E2e Test`.
  /// Falls back to `'My App'` if `pubspec.yaml` is missing or unreadable.
  ///
  /// [root] — absolute path to the Flutter project root.
  /// Returns the human-readable application name string.
  String _getAppName(String root) {
    final pubspecPath = path.join(root, 'pubspec.yaml');
    if (FileHelper.fileExists(pubspecPath)) {
      try {
        final yaml = FileHelper.readYamlFile(pubspecPath);
        final name = yaml['name'] as String? ?? 'My App';
        return name
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
      } catch (_) {
        // pubspec.yaml unreadable or malformed — fall back to default name.
        return 'My App';
      }
    }
    return 'My App';
  }

  // ---------------------------------------------------------------------------
  // Asset & Web Setup
  // ---------------------------------------------------------------------------

  /// Adds `.env` to the `flutter.assets` list in `pubspec.yaml`.
  ///
  /// Ensures the `flutter` section and `assets` list exist. Skips if `.env`
  /// is already registered. Uses `yaml_edit` for safe YAML manipulation.
  ///
  /// [root] — absolute path to the Flutter project root.
  void _registerEnvAsset(String root) {
    final pubspecPath = path.join(root, 'pubspec.yaml');

    if (!FileHelper.fileExists(pubspecPath)) {
      return;
    }

    final content = FileHelper.readFile(pubspecPath);
    final doc = loadYaml(content);

    // 1. Check if .env is already registered — skip if so.
    if (doc is Map && doc['flutter'] is Map) {
      final assets = doc['flutter']['assets'];
      if (assets is List && assets.contains('.env')) {
        return;
      }
    }

    // 2. Build the updated assets list.
    final existingAssets = <String>[];
    if (doc is Map && doc['flutter'] is Map) {
      final assets = doc['flutter']['assets'];
      if (assets is List) {
        existingAssets.addAll(assets.cast<String>());
      }
    }
    existingAssets.add('.env');

    // 3. Write back using yaml_edit.
    final editor = YamlEditor(content);

    try {
      editor.parseAt(['flutter', 'assets']);
      // Path exists — update it.
      editor.update(['flutter', 'assets'], existingAssets);
    } catch (_) {
      // Path doesn't exist — create it.
      try {
        editor.parseAt(['flutter']);
        // flutter key exists but no assets.
        editor.update(['flutter', 'assets'], existingAssets);
      } catch (_) {
        // flutter key doesn't exist at all.
        editor.update(['flutter'], {'assets': existingAssets});
      }
    }

    FileHelper.writeFile(pubspecPath, editor.toString());
  }

  /// Downloads `sqlite3.wasm` to the `web/` directory for web platform support.
  ///
  /// Reads the resolved sqlite3 version from `pubspec.lock` and downloads the
  /// matching WASM binary from GitHub releases. Skips if the file already exists.
  /// Prints a warning with a manual download URL on failure.
  ///
  /// [root] — absolute path to the Flutter project root.
  Future<void> _setupWebSupport(String root) async {
    final targetPath = path.join(root, 'web', 'sqlite3.wasm');

    if (FileHelper.fileExists(targetPath)) {
      return;
    }

    final version = _resolveSqliteVersion(root);
    final url = Uri.parse(
      'https://github.com/simolus3/sqlite3.dart'
      '/releases/download/sqlite3-$version/sqlite3.wasm',
    );

    info('Downloading sqlite3.wasm ($version) for web support...');

    final downloaded = await downloadFile(url, targetPath);

    if (downloaded) {
      info('sqlite3.wasm downloaded to web/');
    } else {
      warn('Could not download sqlite3.wasm automatically.');
      warn('Download manually from: $url');
    }
  }

  /// Resolves the sqlite3 package version from `pubspec.lock`.
  ///
  /// Falls back to a known-good version if `pubspec.lock` is missing or does
  /// not contain the sqlite3 package (e.g. before `flutter pub get`).
  ///
  /// [root] — absolute path to the Flutter project root.
  /// Returns the version string (e.g. `'2.4.6'`).
  String _resolveSqliteVersion(String root) {
    const fallback = '2.4.6';
    final lockPath = path.join(root, 'pubspec.lock');

    if (!FileHelper.fileExists(lockPath)) {
      return fallback;
    }

    try {
      final content = FileHelper.readFile(lockPath);
      final yaml = loadYaml(content) as YamlMap?;
      final packages = yaml?['packages'] as YamlMap?;
      final sqlite3 = packages?['sqlite3'] as YamlMap?;
      final version = sqlite3?['version'] as String?;

      return version ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Downloads a file from [url] to [targetPath].
  ///
  /// Returns `true` on success, `false` on failure. Creates parent directories
  /// if they do not exist. Overridable in tests to avoid real HTTP requests.
  ///
  /// [url] — the remote URL to download from.
  /// [targetPath] — the local file path to write to.
  Future<bool> downloadFile(Uri url, String targetPath) async {
    final client = HttpClient();

    try {
      // 1. Follow redirects and fetch the response.
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode != 200) {
        await response.drain<void>();
        return false;
      }

      // 2. Ensure target directory exists.
      final file = File(targetPath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      // 3. Stream response body to disk.
      await response.pipe(file.openWrite());

      return true;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Writes [content] to [filePath] only if the file does not already exist.
  ///
  /// Preserves any customisations the developer may have made after the initial
  /// install run.
  ///
  /// [filePath] — absolute path to the target file.
  /// [content] — file contents to write on first creation.
  void _writeIfNotExists(String filePath, String content) {
    if (!FileHelper.fileExists(filePath)) {
      FileHelper.writeFile(filePath, content);
    }
  }
}
