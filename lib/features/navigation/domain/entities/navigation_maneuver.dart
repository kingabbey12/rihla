import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';

/// Current or upcoming turn-by-turn maneuver.
class NavigationManeuver {
  const NavigationManeuver({
    required this.type,
    required this.instruction,
    required this.distanceToManeuverKm,
    required this.currentRoad,
    required this.nextRoad,
    this.isPlaceholder = false,
  });

  final ManeuverType type;
  final String instruction;
  final double distanceToManeuverKm;
  final String currentRoad;
  final String nextRoad;
  final bool isPlaceholder;

  NavigationManeuver copyWith({
    ManeuverType? type,
    String? instruction,
    double? distanceToManeuverKm,
    String? currentRoad,
    String? nextRoad,
    bool? isPlaceholder,
  }) {
    return NavigationManeuver(
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      distanceToManeuverKm: distanceToManeuverKm ?? this.distanceToManeuverKm,
      currentRoad: currentRoad ?? this.currentRoad,
      nextRoad: nextRoad ?? this.nextRoad,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationManeuver &&
          type == other.type &&
          instruction == other.instruction &&
          distanceToManeuverKm == other.distanceToManeuverKm &&
          currentRoad == other.currentRoad &&
          nextRoad == other.nextRoad &&
          isPlaceholder == other.isPlaceholder;

  @override
  int get hashCode => Object.hash(
        type,
        instruction,
        distanceToManeuverKm,
        currentRoad,
        nextRoad,
        isPlaceholder,
      );
}
