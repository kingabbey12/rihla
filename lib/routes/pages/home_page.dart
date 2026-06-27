import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Blank home screen — the application entry point.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeTitle)),
      body: const SizedBox.shrink(),
    );
  }
}
