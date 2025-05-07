import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String THEME_KEY = 'theme_preference';
  bool _isDark = false;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeData get theme => _isDark ? darkTheme : lightTheme;

  bool get isDark => _isDark;

  void _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(THEME_KEY) ?? false;
    notifyListeners();
  }

  void _saveThemeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(THEME_KEY, _isDark);
  }

  void toggleTheme() {
    _isDark = !_isDark;
    _saveThemeToPrefs();
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _isDark = isDark;
    _saveThemeToPrefs();
    notifyListeners();
  }
}
