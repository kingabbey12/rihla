import 'dart:convert';

import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BetaFeedbackLocalDatasource {
  BetaFeedbackLocalDatasource(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'beta_feedback_queue_v1';

  List<BetaFeedback> getAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BetaFeedback.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<BetaFeedback> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((f) => f.toJson()).toList()),
    );
  }
}
