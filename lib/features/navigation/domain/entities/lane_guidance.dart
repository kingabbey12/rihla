/// Lane direction indicator for lane guidance UI.
enum LaneDirection {
  straight,
  slightLeft,
  slightRight,
  left,
  right,
  uTurn,
}

/// A single lane in a lane-guidance strip.
class LaneIndicator {
  const LaneIndicator({
    required this.direction,
    required this.isRecommended,
    this.isPlaceholder = true,
  });

  final LaneDirection direction;
  final bool isRecommended;

  /// True until live lane data is available.
  final bool isPlaceholder;
}

/// Placeholder lane guidance attached to the navigation session.
class LaneGuidance {
  const LaneGuidance({
    required this.lanes,
    this.isPlaceholder = true,
  });

  final List<LaneIndicator> lanes;
  final bool isPlaceholder;

  static const empty = LaneGuidance(lanes: [], isPlaceholder: true);
}
