/// Categories of beta feedback supported by the in-app flow.
enum BetaFeedbackType {
  bugReport('bug_report', 'Bug report'),
  featureRequest('feature_request', 'Feature request'),
  journeyFeedback('journey_feedback', 'Journey feedback'),
  routingIssue('routing_issue', 'Incorrect routing'),
  placeIssue('place_issue', 'Incorrect place info'),
  mapCorrection('map_correction', 'Map issue'),
  speedCameraIssue('speed_camera_issue', 'Speed camera issue'),
  salikIssue('salik_issue', 'Salik issue'),
  aiFeedback('ai_feedback', 'AI feedback'),
  emergencyFeedback('emergency_feedback', 'Emergency feedback'),
  crashReport('crash_report', 'Crash report');

  const BetaFeedbackType(this.wireName, this.displayName);

  final String wireName;
  final String displayName;
}
