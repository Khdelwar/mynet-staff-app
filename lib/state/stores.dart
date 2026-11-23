import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key/value storage for the session token and the cached profile.
/// Nothing sensitive goes to shared_preferences.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Keystore can be reset by the OS (restore, lock-screen change).
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Best-effort clear.
    }
  }
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

const sessionTokenKey = 'staff_session_token';

/// Last `/me` answer, so the app opens offline. Display only.
const cachedUserKey = 'staff_cached_user';
