import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [Preferences])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(AppDatabase db) : super(db);

  // ========== Generic Get/Set ==========
  Future<String?> get(String key) async {
    final pref = await (select(preferences)..where((t) => t.key.equals(key))).getSingleOrNull();
    return pref?.value;
  }

  Future<void> set(String key, String value) async {
    await into(preferences).insertOnConflictUpdate(
      PreferencesCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  Future<void> remove(String key) async {
    await (delete(preferences)..where((t) => t.key.equals(key))).go();
  }

  Future<void> clear() async {
    await delete(preferences).go();
  }

  // ========== Typed Getters/Setters ==========

  // Boolean
  Future<bool?> getBool(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    await set(key, value.toString());
  }

  // Integer
  Future<int?> getInt(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> setInt(String key, int value) async {
    await set(key, value.toString());
  }

  // Double
  Future<double?> getDouble(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return double.tryParse(value);
  }

  Future<void> setDouble(String key, double value) async {
    await set(key, value.toString());
  }

  // DateTime
  Future<DateTime?> getDateTime(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setDateTime(String key, DateTime value) async {
    await set(key, value.toIso8601String());
  }

  // ========== App-Specific Preferences ==========

  /// Check if seed data has been loaded
  Future<bool> hasSeeded() async {
    return await getBool('has_seeded') ?? false;
  }

  Future<void> setHasSeeded(bool value) async {
    await setBool('has_seeded', value);
  }

  /// Get/Set device ID
  Future<String?> getDeviceId() async {
    return await get('device_id');
  }

  Future<void> setDeviceId(String deviceId) async {
    await set('device_id', deviceId);
  }

  /// Get/Set theme mode
  Future<String?> getThemeMode() async {
    return await get('theme_mode');
  }

  Future<void> setThemeMode(String mode) async {
    await set('theme_mode', mode);
  }

  /// Get/Set TTS enabled
  Future<bool> isTtsEnabled() async {
    return await getBool('tts_enabled') ?? false;
  }

  Future<void> setTtsEnabled(bool enabled) async {
    await setBool('tts_enabled', enabled);
  }

  /// Get/Set TTS rate (slow=0.5, normal=1.0)
  Future<double> getTtsRate() async {
    return await getDouble('tts_rate') ?? 0.5;
  }

  Future<void> setTtsRate(double rate) async {
    await setDouble('tts_rate', rate);
  }

  /// Get/Set banner dismissed timestamp
  Future<DateTime?> getBannerDismissedUntil() async {
    return await getDateTime('banner_dismissed_until');
  }

  Future<void> setBannerDismissedUntil(DateTime dateTime) async {
    await setDateTime('banner_dismissed_until', dateTime);
  }

  /// Get/Set last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    return await getDateTime('last_sync_time');
  }

  Future<void> setLastSyncTime(DateTime dateTime) async {
    await setDateTime('last_sync_time', dateTime);
  }
}
