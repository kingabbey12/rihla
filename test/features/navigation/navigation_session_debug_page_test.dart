import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/presentation/pages/navigation_session_debug_page.dart';

void main() {
  testWidgets('NavigationSessionDebugPage shows idle state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: NavigationSessionDebugPage()),
      ),
    );

    expect(find.text('Navigation Session Debug'), findsOneWidget);
    expect(find.text('Start sample session'), findsOneWidget);
    expect(find.text('No active session'), findsOneWidget);
  });
}
