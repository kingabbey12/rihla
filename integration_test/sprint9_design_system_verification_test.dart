import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/shared/design/rihla_design.dart';
import 'package:rihla/shared/widgets/empty_screen.dart';
import 'package:rihla/shared/widgets/loading_screen.dart';
import 'package:rihla/shared/widgets/rihla_skeleton.dart';
import 'package:rihla/theme/app_theme.dart';

/// Sprint 9 product-wide design system verification on the real macOS runner.
///
/// Captures PNGs (not goldens) demonstrating the shared design language —
/// premium loading skeletons, premium empty states, glass surfaces, gradients
/// and spacing — across light, dark, English and Arabic (RTL).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 9 design system screenshots', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/sprint9_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('sprint9_capture_root')),
      ) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await File('${out.path}/$name.png').writeAsBytes(
          bytes.buffer.asUint8List(),
        );
      }
      image.dispose();
    }

    Widget host({
      required ThemeMode mode,
      required Locale locale,
      required Widget child,
    }) {
      return RepaintBoundary(
        key: const ValueKey('sprint9_capture_root'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> show(
      String name, {
      required ThemeMode mode,
      required Widget child,
      Locale locale = const Locale('en'),
    }) async {
      await tester.pumpWidget(
        host(mode: mode, locale: locale, child: child),
      );
      await settle();
      await capture(name);
    }

    const en = Locale('en');
    const ar = Locale('ar');

    // —— Loading experience: skeletons + contextual message ——
    await show('01_loading_light', mode: ThemeMode.light,
        child: const LoadingScreen(message: 'Finding the best route…'));
    await show('02_loading_dark', mode: ThemeMode.dark,
        child: const LoadingScreen(message: 'Finding the best route…'));

    // —— Empty state: illustration + friendly copy + primary/secondary CTA ——
    Widget emptyDemo() => Scaffold(
          body: EmptyScreen(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved places yet',
            message:
                'Save your home, work and favorite spots to reach them in one tap.',
            actionLabel: 'Add a place',
            onAction: () {},
            secondaryActionLabel: 'Explore nearby',
            onSecondaryAction: () {},
          ),
        );
    await show('03_empty_light', mode: ThemeMode.light, child: emptyDemo());
    await show('04_empty_dark', mode: ThemeMode.dark, child: emptyDemo());
    await show('05_empty_arabic_rtl', mode: ThemeMode.light,
        locale: ar, child: emptyDemo());

    // —— Surface & gradient gallery: glass cards, gradients, skeleton list ——
    await show('06_gallery_light', mode: ThemeMode.light, child: _Gallery());
    await show('07_gallery_dark', mode: ThemeMode.dark, child: _Gallery());

    final overflows = errors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: 'No overflow warnings expected');
  });
}

/// A compact gallery showing the shared glass surfaces, gradient presets and
/// skeleton loaders side by side so cohesion is visible at a glance.
class _Gallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: RihlaContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(RihlaSpacing.xl),
            children: [
              Text('Design System', style: text.displayMedium),
              const SizedBox(height: RihlaSpacing.xs),
              Text(
                'One visual language across Rihla',
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: RihlaSpacing.xl),
              Row(
                children: [
                  _GradientChip('AI', RihlaGradients.ai),
                  const SizedBox(width: RihlaSpacing.md),
                  _GradientChip('Brand', RihlaGradients.brand),
                  const SizedBox(width: RihlaSpacing.md),
                  _GradientChip('Gold', RihlaGradients.gold),
                ],
              ),
              const SizedBox(height: RihlaSpacing.xl),
              RihlaGlassSurface(
                blur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Glass surface', style: text.titleMedium),
                    const SizedBox(height: RihlaSpacing.sm),
                    Text(
                      'Unified blur, opacity, border, radius and shadow.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RihlaSpacing.xl),
              Text('Loading placeholders', style: text.titleMedium),
              const SizedBox(height: RihlaSpacing.md),
              const RihlaSkeletonList(itemCount: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientChip extends StatelessWidget {
  const _GradientChip(this.label, this.gradient);

  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: RihlaRadii.lgAll,
          boxShadow: RihlaShadows.soft(),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
