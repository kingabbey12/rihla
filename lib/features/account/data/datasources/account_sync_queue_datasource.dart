import 'dart:convert';

import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline write queue for cloud sync.
class AccountSyncQueueDatasource {
  AccountSyncQueueDatasource(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'account_sync_queue';

  List<QueuedSyncWrite> getQueue() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => QueuedSyncWrite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> enqueue(QueuedSyncWrite write) async {
    final queue = getQueue()..add(write);
    await _save(queue);
  }

  Future<void> remove(String id) async {
    final queue = getQueue()..removeWhere((w) => w.id == id);
    await _save(queue);
  }

  Future<void> clear() async => _prefs.remove(_key);

  Future<void> _save(List<QueuedSyncWrite> queue) async {
    await _prefs.setString(
      _key,
      jsonEncode(queue.map((w) => w.toJson()).toList()),
    );
  }
}

class QueuedSyncWrite {
  const QueuedSyncWrite({
    required this.id,
    required this.category,
    required this.payload,
    required this.queuedAt,
    this.retryCount = 0,
  });

  final String id;
  final SyncCategory category;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int retryCount;

  QueuedSyncWrite copyWith({int? retryCount}) {
    return QueuedSyncWrite(
      id: id,
      category: category,
      payload: payload,
      queuedAt: queuedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedSyncWrite.fromJson(Map<String, dynamic> json) {
    return QueuedSyncWrite(
      id: json['id'] as String,
      category: SyncCategory.values.firstWhere(
        (c) => c.name == json['category'],
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}
