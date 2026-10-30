import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores Supabase sessions and PKCE verifiers through the platform secure
/// storage plugin instead of plain SharedPreferences.
class SupabaseSecureStorage extends LocalStorage implements GotrueAsyncStorage {
  SupabaseSecureStorage({
    required String projectHost,
    FlutterSecureStorage? storage,
  }) : _sessionKey = 'mamba.supabase.session.$projectHost',
       _pkcePrefix = 'mamba.supabase.pkce.$projectHost.',
       _storage = storage ?? const FlutterSecureStorage();

  final String _sessionKey;
  final String _pkcePrefix;
  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      await _storage.read(key: _sessionKey) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$_pkcePrefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_pkcePrefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$_pkcePrefix$key');
}
