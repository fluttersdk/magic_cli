/// View stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:view` command.
library;

/// Stateless view stub — MagicView with auto-injected controller.
const String viewStub = r'''
import 'package:flutter/material.dart';

// TODO: Import your controller
// import '../../../app/controllers/{{ snakeName }}_controller.dart';

/// {{ className }} View.
class {{ className }}View extends StatelessWidget {
  const {{ className }}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{ className }}'),
      ),
      body: const Center(
        child: Text('{{ className }} View'),
      ),
    );
  }
}
''';

/// Stateful view stub — MagicStatefulView with lifecycle hooks.
const String viewStatefulStub = r'''
import 'package:flutter/material.dart';

// TODO: Import your controller
// import '../../../app/controllers/{{ snakeName }}_controller.dart';

/// {{ className }} View (stateful).
class {{ className }}View extends StatefulWidget {
  const {{ className }}View({super.key});

  @override
  State<{{ className }}View> createState() => _{{ className }}ViewState();
}

class _{{ className }}ViewState extends State<{{ className }}View> {
  @override
  void initState() {
    super.initState();
    // Initialize resources here.
  }

  @override
  void dispose() {
    // Clean up resources before disposal.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{ className }}'),
      ),
      body: const Center(
        child: Text('{{ className }} View'),
      ),
    );
  }
}
''';
