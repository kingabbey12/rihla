/// Playback state for route simulation.
enum SimulationPlayback {
  stopped,
  playing,
  paused,
}

/// Simulation controls stored on the navigation session.
class NavigationSimulation {
  const NavigationSimulation({
    this.playback = SimulationPlayback.playing,
    this.speedMultiplier = 1.0,
  });

  final SimulationPlayback playback;
  final double speedMultiplier;

  NavigationSimulation copyWith({
    SimulationPlayback? playback,
    double? speedMultiplier,
  }) {
    return NavigationSimulation(
      playback: playback ?? this.playback,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationSimulation &&
          playback == other.playback &&
          speedMultiplier == other.speedMultiplier;

  @override
  int get hashCode => Object.hash(playback, speedMultiplier);
}
