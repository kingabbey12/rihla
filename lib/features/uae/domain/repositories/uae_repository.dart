import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/entities/uae_preferences.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';

/// UAE intelligence persistence boundary.
abstract class UaeRepository {
  UaePreferences getPreferences();
  Future<UaePreferences> savePreferences(UaePreferences preferences);

  UaeIntelligenceSnapshot? getLastSnapshot();
  Future<void> saveSnapshot(UaeIntelligenceSnapshot snapshot);
}
