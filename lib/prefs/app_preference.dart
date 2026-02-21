
import 'package:hobit_worker/prefs/preference_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreference {
  static final AppPreference _appPreference = AppPreference._internal();

  factory AppPreference() {
    return _appPreference;
  }

  AppPreference._internal();

  SharedPreferences? _preferences;

  Future<void> initialAppPreference() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future setString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  String getString(String key, {String defValue = ''}) {
    return _preferences?.getString(key) != null
        ? (_preferences?.getString(key) ?? '')
        : defValue;
  }

  Future setInt(String key, int value) async {
    await _preferences?.setInt(key, value);
  }

  int getInt(String key, {int defValue = 0}) {
    return _preferences?.getInt(key) != null
        ? (_preferences?.getInt(key) ?? 0)
        : defValue;
  }

  Future setBool(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }

  bool getBool(String key, {bool defValue = false}) {
    return _preferences?.getBool(key) ?? defValue;
  }

  Future<void> clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("✅ SharedPreferences cleared");
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  String get uName => getString(PreferencesKey.userId);
}