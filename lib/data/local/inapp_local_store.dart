import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the state required by the In-App `/objectMessage` flow across
/// sessions: the `app_id` returned by the subscription, the device
/// registration token, and the `firstAccess` flag.
class InAppLocalStore {
  static const String appIdKey = 'inngage_app_id';
  static const String registrationKey = 'inngage_registration';
  static const String firstAccessKey = 'inngage_inapp_first_access';

  /// Keys written by the removed push-based In-App flow (< 4.0.0).
  static const List<String> _legacyKeys = ['inapp', 'metadata'];

  final FlutterSecureStorage _storage;

  const InAppLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSubscription({
    required int appId,
    required String registration,
  }) async {
    await _storage.write(key: appIdKey, value: appId.toString());
    await _storage.write(key: registrationKey, value: registration);
  }

  Future<int?> readAppId() async {
    final value = await _storage.read(key: appIdKey);
    return value == null ? null : int.tryParse(value);
  }

  Future<String?> readRegistration() => _storage.read(key: registrationKey);

  /// `true` until the first successful (HTTP 200) `/objectMessage` fetch.
  Future<bool> readFirstAccess() async {
    return await _storage.read(key: firstAccessKey) != 'false';
  }

  /// Only call after a successful fetch — a failed first attempt still counts
  /// as first access on the next one.
  Future<void> markFirstAccessConsumed() =>
      _storage.write(key: firstAccessKey, value: 'false');

  Future<void> clearLegacyInAppKeys() async {
    for (final key in _legacyKeys) {
      await _storage.delete(key: key);
    }
  }
}
