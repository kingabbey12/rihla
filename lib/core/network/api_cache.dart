/// In-memory GET response cache with TTL.
class ApiCache {
  ApiCache({this.defaultTtl = const Duration(minutes: 5)});

  final Duration defaultTtl;
  final Map<String, _CacheEntry> _store = {};

  String? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.expiresAt.isBefore(DateTime.now())) {
      _store.remove(key);
      return null;
    }
    return entry.body;
  }

  void put(String key, String body, {Duration? ttl}) {
    _store[key] = _CacheEntry(
      body: body,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  String? getStale(String key) => _store[key]?.body;

  void clear() => _store.clear();
}

class _CacheEntry {
  const _CacheEntry({required this.body, required this.expiresAt});

  final String body;
  final DateTime expiresAt;
}
