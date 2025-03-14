import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static late SharedPreferences _pref;

  static Future<void> init() async {
    _pref = await SharedPreferences.getInstance();
  }

  static Future<bool> setString(String key, String value) async => await _pref.setString(key, value);
  static Future<bool> setInt(String key, int value) async => await _pref.setInt(key, value);
  static Future<bool> setDouble(String key, double value) async => await _pref.setDouble(key, value);
  static Future<bool> setBool(String key, bool value) async => await _pref.setBool(key, value);
  static Future<bool> setStringList(String key, List<String> value) async => await _pref.setStringList(key, value);

  // Getters
  static String? getString(String key) => _pref.getString(key);
  static int? getInt(String key) => _pref.getInt(key);
  static double? getDouble(String key) => _pref.getDouble(key);
  static bool? getBool(String key) => _pref.getBool(key);
  static List<String>? getStringList(String key) => _pref.getStringList(key);

  // Remove a specific key
  static Future<bool> remove(String key) async => await _pref.remove(key);

  // Clear all preferences
  static Future<bool> clear() async => await _pref.clear();
}