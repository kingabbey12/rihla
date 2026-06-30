import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Classic red-ring speed limit badge (US/EU MUTCD-style) used in the HUD.
///
/// [limitKmh] may be null or non-positive when the limit is unknown; in that
/// case a "--" placeholder is shown so the badge never disappears during
/// active navigation.
class SpeedLimitBadge extends StatelessWidget {
  const SpeedLimitBadge({required this.limitKmh, super.key, this.size = 52});

  final int? limitKmh;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasLimit = (limitKmh ?? 0) > 0;
    final valueLabel = hasLimit ? '$limitKmh' : '--';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD32F2F), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.navLimitLabel,
            style: TextStyle(
              color: const Color(0xFF7A1212),
              fontSize: size * 0.16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            valueLabel,
            style: TextStyle(
              color: Colors.black,
              fontSize: size * 0.36,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
