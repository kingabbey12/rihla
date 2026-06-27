import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback.dart';

sealed class BetaFeedbackState {}

class BetaFeedbackIdle extends BetaFeedbackState {}

class BetaFeedbackSubmitting extends BetaFeedbackState {}

class BetaFeedbackSubmitted extends BetaFeedbackState {
  BetaFeedbackSubmitted(this.feedback);
  final BetaFeedback feedback;
}

class BetaFeedbackError extends BetaFeedbackState {
  BetaFeedbackError(this.message);
  final String message;
}
