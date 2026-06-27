import 'dart:convert';

import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline queue for emergency events awaiting network sync.
class EmergencyQueueLocalDatasource {
  EmergencyQueueLocalDatasource(this._prefs);

  final SharedPreferences _prefs;
  static const _queueKey = 'emergency_event_queue';

  List<EmergencyQueuedEvent> getQueue() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => EmergencyQueuedEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQueue(List<EmergencyQueuedEvent> events) async {
    await _prefs.setString(
      _queueKey,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> enqueue(EmergencyQueuedEvent event) async {
    final queue = getQueue()..add(event);
    await saveQueue(queue);
  }

  Future<void> remove(String eventId) async {
    final queue = getQueue()..removeWhere((e) => e.id == eventId);
    await saveQueue(queue);
  }

  Future<void> upsert(EmergencyQueuedEvent event) async {
    final queue = getQueue();
    final index = queue.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      queue[index] = event;
    } else {
      queue.add(event);
    }
    await saveQueue(queue);
  }
}
