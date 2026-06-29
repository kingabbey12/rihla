import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Builds a visible, branded error surface for uncaught widget build failures.
///
/// Installed as [ErrorWidget.builder] so a thrown exception while building any
/// widget (e.g. during the navigation transition) renders a readable card
/// instead of a bare white/grey/red screen. In debug builds the exception and
/// stack are shown to make root-causing trivial; release builds show a friendly
/// message only.
Widget buildAppErrorWidget(FlutterErrorDetails details) {
  return _AppErrorWidget(details: details);
}

class _AppErrorWidget extends StatelessWidget {
  const _AppErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    // Use a self-contained MediaQuery/Directionality-free surface: this widget
    // can be inserted anywhere in the tree, including above MaterialApp, so it
    // must not depend on inherited Material/Directionality widgets.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF0B1320),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong rendering this screen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        details.exceptionAsString(),
                        style: const TextStyle(
                          color: Color(0xFFFFD7D7),
                          fontSize: 13,
                          height: 1.4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
