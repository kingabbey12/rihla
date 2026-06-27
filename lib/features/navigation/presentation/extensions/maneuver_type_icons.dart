import 'package:flutter/material.dart';
import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';

/// Maps maneuver types to Material icons for the turn banner.
extension ManeuverTypeIcons on ManeuverType {
  IconData get icon => switch (this) {
        ManeuverType.continueStraight => Icons.straight,
        ManeuverType.turnLeft => Icons.turn_left,
        ManeuverType.turnRight => Icons.turn_right,
        ManeuverType.slightLeft => Icons.turn_slight_left,
        ManeuverType.slightRight => Icons.turn_slight_right,
        ManeuverType.uTurn => Icons.u_turn_left,
        ManeuverType.merge => Icons.merge,
        ManeuverType.exit => Icons.exit_to_app,
        ManeuverType.roundabout => Icons.roundabout_left,
        ManeuverType.arrive => Icons.flag,
      };
}
