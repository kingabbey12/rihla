import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';

/// Caches enriched [AiContext] to avoid rebuilding prompts unnecessarily.
class AiContextCache {
  final _cache = <String, AiContext>{};

  AiContext? get(String key) => _cache[key];

  void put(AiContext context) => _cache[context.cacheKey] = context;

  void invalidate(String key) => _cache.remove(key);

  void clear() => _cache.clear();
}
