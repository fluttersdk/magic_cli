/// View stub templates for Magic CLI code generation.
///
/// Provides raw string constants for the `magic make:view` command.
library;

/// Stateless view stub — MagicView with auto-injected controller.
const String viewStub = r'''
import 'package:flutter/material.dart';
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

import '../../../app/controllers/{{ snakeName }}_controller.dart';

/// {{ className }} View.
class {{ className }}View extends MagicView<{{ className }}Controller> {
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
import 'package:fluttersdk_magic/fluttersdk_magic.dart';

import '../../../app/controllers/{{ snakeName }}_controller.dart';

/// {{ className }} View (stateful).
class {{ className }}View extends MagicStatefulView<{{ className }}Controller> {
  const {{ className }}View({super.key});

  @override
  State<{{ className }}View> createState() => _{{ className }}ViewState();
}

class _{{ className }}ViewState
    extends MagicStatefulViewState<{{ className }}Controller, {{ className }}View> {
  @override
  void onInit() {
    // Called after initState — controller is available here.
  }

  @override
  void onClose() {
    // Clean up resources before disposal.
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
