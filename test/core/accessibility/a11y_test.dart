import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/accessibility/a11y.dart';

void main() {
  testWidgets('clampedTextScaler clamps oversized OS scaling', (tester) async {
    late TextScaler scaler;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: Builder(
          builder: (context) {
            scaler = A11y.clampedTextScaler(context);
            return const SizedBox();
          },
        ),
      ),
    );
    // 3.0 should be clamped down to the max bound (1.6).
    expect(scaler.scale(10), A11y.maxTextScale * 10);
  });

  testWidgets('clampedTextScaler raises tiny OS scaling to min bound',
      (tester) async {
    late TextScaler scaler;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
        child: Builder(
          builder: (context) {
            scaler = A11y.clampedTextScaler(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(scaler.scale(10), A11y.minTextScale * 10);
  });

  testWidgets('AccessibleIconButton exposes a semantic label and is tappable',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleIconButton(
            icon: Icons.sos,
            label: 'Activate emergency',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Activate emergency'), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(tapped, isTrue);
  });

  testWidgets('MinTouchTarget enforces a 48dp minimum', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MinTouchTarget(
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(MinTouchTarget));
    expect(size.width, greaterThanOrEqualTo(A11y.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(A11y.minTouchTarget));
  });
}
