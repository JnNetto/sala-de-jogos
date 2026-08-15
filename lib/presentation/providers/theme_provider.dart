import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/app_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  AppPreferences _preferences = AppPreferences();
  bool _isLoading = false;

  AppPreferences get preferences => _preferences;
  bool get isDarkMode => _preferences.isDarkMode;
  bool get isLoading => _isLoading;

  static const String _prefsKey = 'app_preferences';

  Future<void> carregarPreferencias() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);

      if (json != null) {
        final decoded = Map<String, dynamic>.from(
          Uri.decodeComponent(json).split('&').fold<Map<String, dynamic>>({}, (
            map,
            pair,
          ) {
            final parts = pair.split('=');
            if (parts.length == 2) {
              map[parts[0]] = parts[1] == 'true'
                  ? true
                  : parts[1] == 'false'
                  ? false
                  : parts[1];
            }
            return map;
          }),
        );
        _preferences = AppPreferences.fromJson(decoded);
      }
    } catch (e) {
      _preferences = AppPreferences();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _preferences = _preferences.copyWith(isDarkMode: !_preferences.isDarkMode);
    notifyListeners();
    await _salvarPreferencias();
  }

  Future<void> setDarkMode(bool isDark) async {
    _preferences = _preferences.copyWith(isDarkMode: isDark);
    notifyListeners();
    await _salvarPreferencias();
  }

  Future<void> _salvarPreferencias() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _preferences.toJson();
      final encoded = json.entries.map((e) => '${e.key}=${e.value}').join('&');
      await prefs.setString(_prefsKey, Uri.encodeComponent(encoded));
    } catch (e) {
      // Erro ao salvar
    }
  }
}
