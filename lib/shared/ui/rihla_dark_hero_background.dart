import 'package:flutter/material.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Dark hero background with skyline gradient for launch/auth screens.
class RihlaDarkHeroBackground extends StatelessWidget {
  const RihlaDarkHeroBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1520),
            RihlaReferenceTokens.darkHero,
            Color(0xFF121820),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle skyline silhouette
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: CustomPaint(painter: _SkylinePainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.08, size.height * 0.35)
      ..lineTo(size.width * 0.12, size.height * 0.55)
      ..lineTo(size.width * 0.18, size.height * 0.25)
      ..lineTo(size.width * 0.22, size.height * 0.55)
      ..lineTo(size.width * 0.30, size.height * 0.40)
      ..lineTo(size.width * 0.38, size.height * 0.15)
      ..lineTo(size.width * 0.42, size.height * 0.55)
      ..lineTo(size.width * 0.50, size.height * 0.30)
      ..lineTo(size.width * 0.58, size.height * 0.55)
      ..lineTo(size.width * 0.65, size.height * 0.20)
      ..lineTo(size.width * 0.70, size.height * 0.55)
      ..lineTo(size.width * 0.78, size.height * 0.38)
      ..lineTo(size.width * 0.85, size.height * 0.55)
      ..lineTo(size.width * 0.92, size.height * 0.28)
      ..lineTo(size.width, size.height * 0.50)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
