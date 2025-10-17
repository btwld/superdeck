import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for accessing local storage using SharedPreferences.
///
/// SharedPreferences stores data in the Application Support directory
/// which is NOT synced to iCloud, avoiding timeout issues.
///
/// Usage example:
/// ```dart
/// // Save a value
/// await StorageHelper.setString('key', 'value');
///
/// // Get a value
/// final value = await StorageHelper.getString('key');
/// ```
class StorageHelper {
  StorageHelper._();

  /// Get a string value from storage
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Set a string value in storage
  static Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  /// Get an int value from storage
  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  /// Set an int value in storage
  static Future<bool> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  /// Get a bool value from storage
  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  /// Set a bool value in storage
  static Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  /// Remove a value from storage
  static Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  /// Clear all values from storage
  static Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  /// Check if a key exists in storage
  static Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}

