import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_storage.dart';

/// Paikallinen tallennus SharedPreferencesin kautta.
/// Data säilyy laitteella kunnes sovellus poistetaan tai data tyhjennetään.
class SharedPreferencesStorage implements KeyValueStorage {
  SharedPreferencesStorage([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<String?> get(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  @override
  Future<void> set(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }
}
