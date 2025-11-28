import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Secure storage for sensitive data like tokens
  static Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  // Regular storage for app data
  static Future<void> store(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> storeJson(String key, Map<String, dynamic> data) async {
    await store(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await get(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<void> storeList(String key, List<Map<String, dynamic>> data) async {
    await store(key, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> getList(String key) async {
    final jsonString = await get(key);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}