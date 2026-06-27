import 'package:rihla/features/uae/domain/entities/uae_alert.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/services/uae_compliance_service.dart';

/// Reusable compliance layer for UAE intelligence.
class UaeComplianceServiceImpl implements UaeComplianceService {
  static const _blockedPhrases = [
    'speed up',
    'go faster',
    'exceed the limit',
    'pay now',
    'auto-pay',
    'automatic payment',
    'skip the toll',
  ];

  @override
  List<UaeAlert> filterAlerts(List<UaeAlert> alerts) {
    return alerts.where((a) => validateAlertMessage(a.message)).toList();
  }

  @override
  UaeIntelligenceSnapshot sanitizeSnapshot(UaeIntelligenceSnapshot snapshot) {
    return UaeIntelligenceSnapshot(
      region: snapshot.region,
      roadType: snapshot.roadType,
      alerts: filterAlerts(snapshot.alerts),
      drivingRules: snapshot.drivingRules,
      weatherAlerts: snapshot.weatherAlerts,
      holidayTraffic: snapshot.holidayTraffic,
      salikSummary: snapshot.salikSummary,
      regionalServices: snapshot.regionalServices,
      emergencyContacts: snapshot.emergencyContacts,
      evaluatedAt: snapshot.evaluatedAt,
    );
  }

  @override
  bool validateAlertMessage(String message) {
    final lower = message.toLowerCase();
    for (final phrase in _blockedPhrases) {
      if (lower.contains(phrase)) return false;
    }
    return true;
  }
}
