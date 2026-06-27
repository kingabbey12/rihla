import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';

/// Emergency platform controller state.
sealed class EmergencyState {
  const EmergencyState();
}

class EmergencyIdle extends EmergencyState {
  const EmergencyIdle();
}

class EmergencySosCountdown extends EmergencyState {
  const EmergencySosCountdown({required this.secondsRemaining});

  final int secondsRemaining;
}

class EmergencySosConfirming extends EmergencyState {
  const EmergencySosConfirming();
}

class EmergencySosSent extends EmergencyState {
  const EmergencySosSent({required this.incidentId, this.queued = false});

  final String incidentId;
  final bool queued;
}

class EmergencyIncidentReporting extends EmergencyState {
  const EmergencyIncidentReporting({required this.incident});

  final EmergencyIncident incident;
}

class EmergencyRoadsideActive extends EmergencyState {
  const EmergencyRoadsideActive({required this.request});

  final RoadsideRequest request;
}

class EmergencyActive extends EmergencyState {
  const EmergencyActive({
    required this.incidents,
    required this.pendingQueueCount,
  });

  final List<EmergencyIncident> incidents;
  final int pendingQueueCount;
}

class EmergencyError extends EmergencyState {
  const EmergencyError({required this.message});

  final String message;
}
