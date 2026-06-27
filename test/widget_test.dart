import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/app.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/routes/route_paths.dart';

void main() {
  testWidgets('App enters the production map experience when launch is complete',
      (tester) async {
    SharedPreferences.setMockInitialValues({'launch_flow_completed': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const App(),
      ),
    );
    // A single frame resolves the launch-complete redirect. We assert on the
    // router target rather than settling, because the map page owns a native
    // surface and an indefinite loading indicator.
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final router = container.read(appRouterProvider);
    expect(router.state.matchedLocation, RoutePaths.maps);
  });
}
