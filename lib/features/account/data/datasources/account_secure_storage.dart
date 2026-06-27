import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for auth tokens and sensitive cache.
class AccountSecureStorage {
  AccountSecureStorage({
    FlutterSecureStorage? storage,
    Map<String, String>? memoryStore,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _memory = memoryStore;

  final FlutterSecureStorage _storage;
  final Map<String, String>? _memory;

  static const _accessTokenKey = 'account_access_token';
  static const _refreshTokenKey = 'account_refresh_token';
  static const _medicalCacheKey = 'account_medical_cache_enc';

  Future<void> _write(String key, String value) async {
    if (_memory != null) {
      _memory![key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    if (_memory != null) return _memory![key];
    return _storage.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (_memory != null) {
      _memory!.remove(key);
      return;
    }
    await _storage.delete(key: key);
  }

  Future<void> saveTokens({
    String? accessToken,
    String? refreshToken,
  }) async {
    if (accessToken != null) {
      await _write(_accessTokenKey, accessToken);
    }
    if (refreshToken != null) {
      await _write(_refreshTokenKey, refreshToken);
    }
  }

  Future<String?> getAccessToken() => _read(_accessTokenKey);
  Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  Future<void> clearTokens() async {
    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
  }

  Future<void> saveMedicalCache(Map<String, String> data) async {
    await _write(_medicalCacheKey, jsonEncode(data));
  }

  Future<Map<String, String>> getMedicalCache() async {
    final raw = await _read(_medicalCacheKey);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> clearAll() async {
    if (_memory != null) {
      _memory!.clear();
      return;
    }
    await _storage.deleteAll();
  }
}
