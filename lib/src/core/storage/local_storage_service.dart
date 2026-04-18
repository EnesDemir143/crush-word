import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStorageService {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);
}

class SharedPreferencesLocalStorageService implements LocalStorageService {
  Future<SharedPreferences> get _preferences async {
    return SharedPreferences.getInstance();
  }

  @override
  Future<String?> readString(String key) async {
    final SharedPreferences preferences = await _preferences;
    return preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.remove(key);
  }
}
