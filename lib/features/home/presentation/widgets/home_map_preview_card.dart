import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/home/presentation/providers/home_dashboard_providers.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_entrance.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/shared/design/rihla_glass.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

class HomeMapPreviewCard extends ConsumerWidget {
  const HomeMapPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final location = ref.watch(locationControllerProvider);
    final hasFix = location is LocationActive;

    return HomeDashboardEntrance(
      delayMs: 380,
      child: HomePressableScale(
        onTap: () {
          ref.read(homeDashboardExpandedProvider.notifier).collapse();
        },
        child: RihlaGlassSurface(
          borderRadius: RihlaRadii.cardAll,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Row(
                  children: [
                    Text(
                      l10n.homeMapPreviewTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.homeOpenFullMap,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: RihlaReferenceTokens.mapTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(RihlaRadii.card),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _MapPreviewPainter(
                        markerActive: hasFix,
                        isDark: theme.brightness == Brightness.dark,
                      ),
                      child: hasFix
                          ? Align(
                              child: _LocationMarker(),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: RihlaReferenceTokens.mapTeal.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: RihlaReferenceTokens.mapTeal,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  _MapPreviewPainter({required this.markerActive, required this.isDark});

  final bool markerActive;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = isDark ? const Color(0xFF1A2630) : const Color(0xFFE9EDF2);
    canvas.drawRect(Offset.zero & size, bg);

    final park = Paint()
      ..color = isDark ? const Color(0xFF243528) : const Color(0xFFD7E8CF);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.38), 48, park);

    final water = Paint()
      ..color = isDark ? const Color(0xFF1E3344) : const Color(0xFFBFD9EE);
    final waterPath = Path()
      ..moveTo(size.width, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.58,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height * 0.42)
      ..close();
    canvas.drawPath(waterPath, water);

    final road = Paint()
      ..color = isDark ? const Color(0xFF3A4550) : Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(0, size.height * 0.52), Offset(size.width, size.height * 0.44), road)
      ..drawLine(Offset(size.width * 0.34, 0), Offset(size.width * 0.48, size.height), road)
      ..drawLine(Offset(0, size.height * 0.74), Offset(size.width, size.height * 0.82), road);

    if (!markerActive) {
      final hint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 4, hint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) =>
      oldDelegate.markerActive != markerActive || oldDelegate.isDark != isDark;
}
