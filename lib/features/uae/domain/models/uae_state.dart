import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';

/// UAE intelligence UI state.
sealed class UaeState {
  const UaeState();
}

class UaeInitial extends UaeState {
  const UaeInitial();
}

class UaeReady extends UaeState {
  const UaeReady({required this.snapshot});

  final UaeIntelligenceSnapshot snapshot;
}

class UaeError extends UaeState {
  const UaeError({required this.message});

  final String message;
}
