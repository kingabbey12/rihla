import 'package:rihla/features/journey/domain/errors/journey_failure.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';

/// Lifecycle state of the journey subsystem.
sealed class JourneyState {
  const JourneyState();
}

/// No active journey planning.
final class JourneyIdle extends JourneyState {
  const JourneyIdle();
}

/// Building a journey preview for the selected destination.
final class JourneyLoading extends JourneyState {
  const JourneyLoading();
}

/// Journey preview ready — show the Journey Card.
final class JourneyPreview extends JourneyState {
  const JourneyPreview(this.summary);

  final JourneySummary summary;
}

/// Journey planning failed.
final class JourneyError extends JourneyState {
  const JourneyError(this.failure);

  final JourneyFailure failure;
}

/// User confirmed Start Journey — routing engine hooks in next phase.
final class JourneyStarted extends JourneyState {
  const JourneyStarted(this.summary);

  final JourneySummary summary;
}
