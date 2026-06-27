/// Placeholder maneuver instruction for the current navigation step.
class NavigationManeuver {
  const NavigationManeuver({
    required this.instruction,
    required this.distanceToManeuverKm,
    this.isPlaceholder = true,
  });

  final String instruction;

  /// Distance remaining until this maneuver, in kilometres.
  final double distanceToManeuverKm;

  /// True when turn-by-turn guidance is not yet implemented.
  final bool isPlaceholder;

  NavigationManeuver copyWith({
    String? instruction,
    double? distanceToManeuverKm,
    bool? isPlaceholder,
  }) {
    return NavigationManeuver(
      instruction: instruction ?? this.instruction,
      distanceToManeuverKm: distanceToManeuverKm ?? this.distanceToManeuverKm,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationManeuver &&
          instruction == other.instruction &&
          distanceToManeuverKm == other.distanceToManeuverKm &&
          isPlaceholder == other.isPlaceholder;

  @override
  int get hashCode =>
      Object.hash(instruction, distanceToManeuverKm, isPlaceholder);
}
