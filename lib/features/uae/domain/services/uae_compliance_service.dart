import 'package:rihla/features/uae/domain/entities/uae_alert.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';

/// Ensures UAE intelligence remains advisory and compliant.
abstract class UaeComplianceService {
  List<UaeAlert> filterAlerts(List<UaeAlert> alerts);
  UaeIntelligenceSnapshot sanitizeSnapshot(UaeIntelligenceSnapshot snapshot);
  bool validateAlertMessage(String message);
}
