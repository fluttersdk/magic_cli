/// Install command stub templates for Magic CLI.
///
/// All methods return valid Dart code strings ready to be written to files.
/// Unlike model_stubs.dart (which uses const String), these methods accept
/// parameters to generate dynamic content based on active feature flags.
library;

/// Install command stub templates.
///
/// All methods are static and return valid Dart source code strings.
/// Use triple-quoted strings (`'''...'''`) with escaped `\$` where needed.
class InstallStubs {
  /// Prevent instantiation — this is a pure static utility class.
  const InstallStubs._();

  // ---------------------------------------------------------------------------
  // main.dart
  // ---------------------------------------------------------------------------

  /// Generates the `lib/main.dart` bootstrap file.
  ///
  /// Produces a full main.dart with `WidgetsFlutterBinding.ensureInitialized()`,
  /// `Magic.init()` with dynamic config factories, and `MagicApplication`.
  ///
  /// [appName] — the human-readable application name (e.g. `My App`).
  /// [configImports] — list of import statements (one per config file).
  /// [configFactories] — list of factory lambda strings (e.g. `() => appConfig`).
  static String mainDartContent({
    required String appName,
    required List<String> configImports,
    required List<String> configFactories,
  }) {
    final imports = configImports.join('\n');
    final factories = configFactories.map((f) => '      $f,').join('\n');

    return '''
import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
$imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Magic.init(
    configFactories: [
$factories
    ],
  );

  runApp(
    MagicApplication(title: '$appName'),
  );
}
''';
  }

  // ---------------------------------------------------------------------------
  // Config files
  // ---------------------------------------------------------------------------

  /// Generates `lib/config/app.dart` with a dynamic providers list.
  ///
  /// [providerImports] — additional provider import statements beyond the
  ///   always-present `RouteServiceProvider` and `AppServiceProvider`.
  /// [providerEntries] — additional `(app) => Provider(app),` strings beyond
  ///   the always-present Route and App providers.
  static String appConfigContent({
    required List<String> providerImports,
    required List<String> providerEntries,
  }) {
    final allImports = [
      "import 'package:magic/magic.dart';",
      "import '../app/providers/app_service_provider.dart';",
      "import '../app/providers/route_service_provider.dart';",
      ...providerImports,
    ].join('\n');

    final allProviders = [
      '      (app) => RouteServiceProvider(app),',
      ...providerEntries.map((e) => '      $e'),
      '      (app) => AppServiceProvider(app),',
    ].join('\n');

    return '''
$allImports

/// Application Configuration.
Map<String, dynamic> get appConfig => {
  'app': {
    'name': env('APP_NAME', 'My App'),
    'env': env('APP_ENV', 'production'),
    'debug': env('APP_DEBUG', false),
    'key': env('APP_KEY'),
    'providers': [
$allProviders
    ],
  },
};
''';
  }

  /// Generates `lib/config/auth.dart` matching the Uptizm production pattern.
  ///
  /// Uses `final Map` (not a getter) — this is the one config exception.
  static String authConfigContent() {
    return r'''
/// Authentication Configuration.
///
/// ## Guards
///
/// - `bearer` / `sanctum` — Bearer token (default)
/// - `basic` — HTTP Basic auth
/// - `api_key` — API key auth
///
/// ## Features
///
/// - User caching (instant restore)
/// - Auto token refresh on 401
/// - Driver-agnostic interceptors
final Map<String, dynamic> authConfig = {
  // ---------------------------------------------------------------------------
  // Defaults
  // ---------------------------------------------------------------------------
  'defaults': {'guard': 'api'},

  // ---------------------------------------------------------------------------
  // Guards
  // ---------------------------------------------------------------------------
  'guards': {
    'api': {'driver': 'bearer'},
  },

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------
  'endpoints': {
    'user': '/auth/user',       // Fetch user on restore
    'refresh': '/auth/refresh', // Refresh access token
  },

  // ---------------------------------------------------------------------------
  // Token
  // ---------------------------------------------------------------------------
  'token': {
    'key': 'auth_token',
    'refresh_key': 'refresh_token',
    'header': 'Authorization',
    'prefix': 'Bearer',
  },

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------
  'cache': {'user_key': 'auth_user'},

  // ---------------------------------------------------------------------------
  // Auto Restore
  // ---------------------------------------------------------------------------
  'auto_refresh': true,
};
''';
  }

  /// Generates `lib/config/database.dart` with SQLite as the default driver.
  static String databaseConfigContent() {
    return r'''
/// Database Configuration.
///
/// Uses SQLite by default. On mobile, files are stored in the app's documents
/// directory. On web, in-memory SQLite is used automatically.
Map<String, dynamic> get databaseConfig => {
  'database': {
    'default': 'sqlite',
    'connections': {
      'sqlite': {
        'driver': 'sqlite',
        'database': 'database.sqlite',
      },
    },
  },
};
''';
  }

  /// Generates `lib/config/network.dart` with a single API driver.
  static String networkConfigContent() {
    return r'''
import 'package:magic/magic.dart';

/// Network Configuration.
///
/// This config file is OPTIONAL. Only create it if you want to use the
/// Magic Network (Http) system. Don't forget to add `NetworkServiceProvider`
/// to your `app.providers` list.
Map<String, dynamic> get networkConfig => {
  'network': {
    'default': 'api',
    'drivers': {
      'api': {
        'base_url': env('API_URL', 'http://localhost:8000/api/v1'),
        'timeout': 10000,
        'headers': {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      },
    },
  },
};
''';
  }

  /// Generates `lib/config/view.dart` with Wind UI dialog/confirm classes.
  static String viewConfigContent() {
    return r'''
/// View Configuration.
///
/// Customizes the appearance of Magic UI components (dialogs, confirms,
/// loading). These className values are read by MagicFeedback via
/// `Config.get('view.*')`.
Map<String, dynamic> get viewConfig => {
  'view': {
    'dialog': {
      'class': 'bg-white dark:bg-gray-800 rounded-xl p-6 shadow-2xl max-w-lg',
    },
    'confirm': {
      'container_class': 'bg-white dark:bg-gray-800 rounded-xl p-6 shadow-2xl w-80',
      'title_class': 'text-lg font-bold text-gray-900 dark:text-white',
      'message_class': 'text-gray-600 dark:text-gray-400 mt-2',
      'button_cancel_class': 'px-4 py-2 text-gray-600 dark:text-gray-300',
      'button_confirm_class': 'px-4 py-2 bg-primary text-white rounded-lg',
      'button_danger_class': 'px-4 py-2 bg-red-500 text-white rounded-lg',
    },
  },
};
''';
  }

  /// Generates `lib/config/cache.dart` with file driver and default TTL.
  ///
  /// Uses the string `'file'` for the driver (not `FileStore()`) so the
  /// generated app does not need to import internal Magic driver classes.
  static String cacheConfigContent() {
    return r'''
/// Cache Configuration.
///
/// - `driver`: `'file'` for persistent disk caching, `'memory'` for session-only.
/// - `ttl`: default time-to-live in seconds.
Map<String, dynamic> get cacheConfig => {
  'cache': {
    'driver': 'file',
    'ttl': 3600,
  },
};
''';
  }

  /// Generates `lib/config/logging.dart` with stack → console channel setup.
  static String loggingConfigContent() {
    return r'''
/// Logging Configuration.
///
/// This config file is OPTIONAL. Only create it if you want to customize
/// the logging behaviour. The default channel is `stack` which logs to console.
Map<String, dynamic> get loggingConfig => {
  'logging': {
    'default': 'stack',
    'channels': {
      'stack': {
        'driver': 'stack',
        'channels': ['console'],
      },
      'console': {
        'driver': 'console',
        'level': 'debug',
      },
    },
  },
};
''';
  }

  // ---------------------------------------------------------------------------
  // Service Providers
  // ---------------------------------------------------------------------------

  /// Generates `lib/app/providers/route_service_provider.dart`.
  ///
  /// Calls `registerKernel()` in `register()` and `registerAppRoutes()` in
  /// `boot()`, matching the Uptizm production pattern.
  static String routeServiceProviderContent() {
    return r'''
import 'package:magic/magic.dart';

import '../kernel.dart';
import '../../routes/app.dart';

/// Route Service Provider.
///
/// Registers the HTTP kernel and application routes.
class RouteServiceProvider extends ServiceProvider {
  RouteServiceProvider(super.app);

  @override
  void register() {
    // Register middleware kernel — runs synchronously during bootstrap.
    registerKernel();
  }

  @override
  Future<void> boot() async {
    // Register application route definitions.
    registerAppRoutes();
  }
}
''';
  }

  /// Generates `lib/app/providers/app_service_provider.dart`.
  ///
  /// Ships with empty `register()` and `boot()` methods and a comment
  /// reminding the developer to call `Auth.manager.setUserFactory()`.
  static String appServiceProviderContent() {
    return r'''
import 'package:magic/magic.dart';

/// Application Service Provider.
///
/// Use this provider to bind your own services to the IoC container and
/// to perform any bootstrap logic that requires other services to be ready.
class AppServiceProvider extends ServiceProvider {
  AppServiceProvider(super.app);

  @override
  void register() {
    // Bind your services here (sync only — do not resolve other services).
    // Example:
    //   app.singleton('my_service', () => MyService());
  }

  @override
  Future<void> boot() async {
    // Perform async bootstrap logic here.
    //
    // IMPORTANT: Call setUserFactory() so Auth.user<T>() returns your model:
    //   Auth.manager.setUserFactory((data) => User.fromMap(data));
  }
}
''';
  }

  // ---------------------------------------------------------------------------
  // Kernel
  // ---------------------------------------------------------------------------

  /// Generates `lib/app/kernel.dart` — the HTTP middleware registry.
  ///
  /// Produces an empty `registerKernel()` function with commented-out examples
  /// showing the Global and Route middleware registration patterns.
  static String kernelDartContent() {
    return r'''
import 'package:magic/magic.dart';

/// The HTTP Kernel.
///
/// Register all middleware here, similar to Laravel's `app/Http/Kernel.php`.
///
/// ## Usage
///
/// This function is called automatically by `RouteServiceProvider.register()`.
/// You do not need to call it manually.
///
/// ## Global Middleware
///
/// Global middleware runs on EVERY route:
///
/// ```dart
/// Kernel.global([
///   () => LoggingMiddleware(),
/// ]);
/// ```
///
/// ## Route Middleware
///
/// Route middleware are named aliases you use in route definitions:
///
/// ```dart
/// Kernel.registerAll({
///   'auth': () => EnsureAuthenticated(),
///   'guest': () => RedirectIfAuthenticated(),
/// });
/// ```
void registerKernel() {
  // ---------------------------------------------------------------------------
  // Global Middleware
  // ---------------------------------------------------------------------------
  // Kernel.global([
  //   () => LoggingMiddleware(),
  // ]);

  // ---------------------------------------------------------------------------
  // Route Middleware
  // ---------------------------------------------------------------------------
  // Uncomment and add your middleware aliases below:
  // Kernel.registerAll({
  //   'auth': () => EnsureAuthenticated(),
  //   'guest': () => RedirectIfAuthenticated(),
  // });
}
''';
  }

  // ---------------------------------------------------------------------------
  // Routes
  // ---------------------------------------------------------------------------

  /// Generates `lib/routes/app.dart` with a single welcome route.
  ///
  /// [appName] — used only for documentation context; not embedded in code.
  static String routesAppContent({required String appName}) {
    return '''
import 'package:magic/magic.dart';

import '../resources/views/welcome_view.dart';

/// Application Route Definitions.
///
/// Register all application routes here. This function is called by
/// [RouteServiceProvider.boot()] during the Magic bootstrap lifecycle.
///
/// See also: `lib/app/kernel.dart` for middleware registration.
void registerAppRoutes() {
  MagicRoute.page('/', () => const WelcomeView());
}
''';
  }

  // ---------------------------------------------------------------------------
  // Views
  // ---------------------------------------------------------------------------

  /// Generates `lib/resources/views/welcome_view.dart`.
  ///
  /// A full Wind UI welcome page showing the app name, framework branding,
  /// and three quick-link cards (Docs, GitHub, CLI Commands).
  ///
  /// [appName] — the human-readable application name shown in the hero section.
  static String welcomeViewContent({required String appName}) {
    return '''
import 'package:flutter/material.dart';
import 'package:fluttersdk_wind/fluttersdk_wind.dart';
import 'package:magic/magic.dart';

/// Welcome view — the default landing page for a new Magic application.
///
/// Displays the application name (read from config), Magic framework branding,
/// and three quick-link cards pointing to Docs, GitHub, and CLI Commands.
class WelcomeView extends StatelessWidget {
  /// Creates the [WelcomeView].
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WDiv(
          className: 'flex flex-col min-h-screen bg-gray-50 dark:bg-gray-900',
          children: [
            // ----------------------------------------------------------------
            // Hero section
            // ----------------------------------------------------------------
            WDiv(
              className: 'flex flex-col items-center justify-center py-16 px-6',
              children: [
                WText(
                  '✨',
                  className: 'text-6xl mb-4',
                ),
                WText(
                  Config.get('app.name', '$appName'),
                  className:
                      'text-4xl font-bold text-gray-900 dark:text-white mb-2',
                ),
                WText(
                  'Built with Magic Framework',
                  className: 'text-base text-gray-500 dark:text-gray-400',
                ),
              ],
            ),

            // ----------------------------------------------------------------
            // Quick-link cards
            // ----------------------------------------------------------------
            WDiv(
              className: 'flex flex-col gap-4 px-6 pb-12',
              children: [
                _QuickLinkCard(
                  icon: '📖',
                  title: 'Documentation',
                  description: 'Read the Magic Framework docs to get started.',
                  url: 'https://github.com/fluttersdk/magic',
                ),
                _QuickLinkCard(
                  icon: '🐙',
                  title: 'GitHub',
                  description:
                      'Star the repo, report issues, or contribute code.',
                  url: 'https://github.com/fluttersdk/magic',
                ),
                _QuickLinkCard(
                  icon: '⚡',
                  title: 'CLI Commands',
                  description:
                      'Run `magic --help` to see all available commands.',
                  url: 'https://github.com/fluttersdk/magic_cli',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal quick-link card widget used by [WelcomeView].
class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.url,
  });

  /// Emoji icon displayed at the top of the card.
  final String icon;

  /// Card heading.
  final String title;

  /// Short description shown below the heading.
  final String description;

  /// Destination URL opened when the card button is tapped.
  final String url;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className:
          'bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm '
          'border border-gray-100 dark:border-gray-700',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-3 mb-2',
          children: [
            WText(icon, className: 'text-2xl'),
            WText(
              title,
              className: 'text-lg font-semibold text-gray-900 dark:text-white',
            ),
          ],
        ),
        WText(
          description,
          className: 'text-sm text-gray-500 dark:text-gray-400 mb-4',
        ),
        WButton(
          onTap: () => Log.info('Opening: \$url'),
          className:
              'py-3 px-4 bg-primary rounded-lg self-start',
          child: WText(
            'Learn more →',
            className: 'text-white text-sm font-medium',
          ),
        ),
      ],
    );
  }
}
''';
  }

  // ---------------------------------------------------------------------------
  // Environment files
  // ---------------------------------------------------------------------------

  /// Generates a `.env` template file with sensible defaults.
  ///
  /// [appName] — written as the default value for `APP_NAME`.
  static String envContent({required String appName}) {
    return '''
APP_NAME="$appName"
APP_ENV=local
APP_DEBUG=true
APP_KEY=

API_URL=http://localhost:8000/api/v1
''';
  }

  /// Generates a `.env.example` template file with empty values.
  ///
  /// Safe to commit — contains keys but no secrets.
  static String envExampleContent() {
    return r'''
APP_NAME=
APP_ENV=
APP_DEBUG=
APP_KEY=

API_URL=
''';
  }
}
