import '../local/db/daos/preferences_dao.dart';

/// Repository for app preferences
class PreferencesRepository {
  final PreferencesDao _dao;

  PreferencesRepository(this._dao);

  // Generic
  Future<String?> get(String key) => _dao.get(key);
  Future<void> set(String key, String value) => _dao.set(key, value);
  Future<void> remove(String key) => _dao.remove(key);
  Future<void> clear() => _dao.clear();

  // Typed
  Future<bool?> getBool(String key) => _dao.getBool(key);
  Future<void> setBool(String key, bool value) => _dao.setBool(key, value);

  Future<int?> getInt(String key) => _dao.getInt(key);
  Future<void> setInt(String key, int value) => _dao.setInt(key, value);

  Future<double?> getDouble(String key) => _dao.getDouble(key);
  Future<void> setDouble(String key, double value) => _dao.setDouble(key, value);

  Future<DateTime?> getDateTime(String key) => _dao.getDateTime(key);
  Future<void> setDateTime(String key, DateTime value) => _dao.setDateTime(key, value);

  // App-specific
  Future<bool> hasSeeded() => _dao.hasSeeded();
  Future<void> setHasSeeded(bool value) => _dao.setHasSeeded(value);

  Future<String?> getDeviceId() => _dao.getDeviceId();
  Future<void> setDeviceId(String deviceId) => _dao.setDeviceId(deviceId);

  Future<String?> getThemeMode() => _dao.getThemeMode();
  Future<void> setThemeMode(String mode) => _dao.setThemeMode(mode);

  Future<bool> isTtsEnabled() => _dao.isTtsEnabled();
  Future<void> setTtsEnabled(bool enabled) => _dao.setTtsEnabled(enabled);

  Future<double> getTtsRate() => _dao.getTtsRate();
  Future<void> setTtsRate(double rate) => _dao.setTtsRate(rate);

  Future<DateTime?> getBannerDismissedUntil() => _dao.getBannerDismissedUntil();
  Future<void> setBannerDismissedUntil(DateTime dateTime) => _dao.setBannerDismissedUntil(dateTime);

  Future<DateTime?> getLastSyncTime() => _dao.getLastSyncTime();
  Future<void> setLastSyncTime(DateTime dateTime) => _dao.setLastSyncTime(dateTime);

  Future<String> getAccessibilityMode() async {
    final mode = await get('accessibility_mode');
    return mode ?? 'defaultNight';
  }

  Future<void> setAccessibilityMode(String mode) => set('accessibility_mode', mode);
}
