import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePalette { classic, amber, darkVoid, mint }

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();
  ThemeManager._internal();

  ThemeMode themeMode = ThemeMode.dark; 
  AppThemePalette currentPalette = AppThemePalette.darkVoid;
  
  double readerFontSize = 18.0;
  String readerFontFamily = 'sans-serif';
  Color readerTextColor = Colors.red;

  // Sihirbaz Hafızası
  int savedReaderMode = 1;
  int savedAdvancedMode = 1;
  int savedSourceType = 1;
  String savedBookId = "";

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.dark.index];
    currentPalette = AppThemePalette.values[prefs.getInt('palette') ?? AppThemePalette.darkVoid.index];
    readerFontSize = prefs.getDouble('fontSize') ?? 18.0;
    readerFontFamily = prefs.getString('fontFamily') ?? 'sans-serif';
    int colorValue = prefs.getInt('textColor') ?? Colors.red.value;
    readerTextColor = Color(colorValue);

    savedReaderMode = prefs.getInt('savedReaderMode') ?? 1;
    savedAdvancedMode = prefs.getInt('savedAdvancedMode') ?? 1;
    savedSourceType = prefs.getInt('savedSourceType') ?? 1;
    savedBookId = prefs.getString('savedBookId') ?? "";

    notifyListeners();
  }

  void saveReaderWizardSettings(int mode, String bookId) async {
    savedReaderMode = mode;
    savedBookId = bookId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('savedReaderMode', mode);
    await prefs.setString('savedBookId', bookId);
  }

  void saveAdvancedWizardSettings(int mode, int source, String bookId) async {
    savedAdvancedMode = mode;
    savedSourceType = source;
    savedBookId = bookId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('savedAdvancedMode', mode);
    await prefs.setInt('savedSourceType', source);
    await prefs.setString('savedBookId', bookId);
  }

  void setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  void setPalette(AppThemePalette palette) async {
    currentPalette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('palette', palette.index);
    notifyListeners();
  }

  void updateReaderSettings(double size, String fontFamily, Color textColor) async {
    readerFontSize = size;
    readerFontFamily = fontFamily;
    readerTextColor = textColor;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    await prefs.setString('fontFamily', fontFamily);
    await prefs.setInt('textColor', textColor.value);
    notifyListeners();
  }

  String getPaletteName(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.classic: return "Klasik";
      case AppThemePalette.amber: return "Kehribar";
      case AppThemePalette.darkVoid: return "Uzay";
      case AppThemePalette.mint: return "Nane";
    }
  }

  Color getVibrantOrpColor() {
    if (readerTextColor == Colors.red) return const Color(0xFFFF1744); 
    if (readerTextColor == Colors.amber) return const Color(0xFFFF9100); 
    if (readerTextColor == Colors.blue) return const Color(0xFF2979FF); 
    if (readerTextColor == Colors.green) return const Color(0xFF00E676); 
    return readerTextColor;
  }

  Color getReaderBackgroundColor() {
    if (themeMode == ThemeMode.dark) return const Color(0xFF121212);
    switch (currentPalette) {
      case AppThemePalette.amber: return const Color(0xFFFDF6E3);
      case AppThemePalette.mint: return const Color(0xFFE8F5E9);
      case AppThemePalette.darkVoid: return const Color(0xFF1A1A24);
      default: return Colors.white;
    }
  }

  Color getReaderTextColor() {
    if (themeMode == ThemeMode.dark) return const Color(0xFFE5E5E5);
    switch (currentPalette) {
      case AppThemePalette.darkVoid: return const Color(0xFFE5E5E5);
      default: return const Color(0xFF2C3E50);
    }
  }

  ThemeData getThemeData(bool isDark) {
    final baseMode = isDark ? ColorScheme.dark : ColorScheme.light;
    Color primaryColor = Colors.blue;

    if (!isDark) {
      switch (currentPalette) {
        case AppThemePalette.amber: primaryColor = Colors.amber.shade900; break;
        case AppThemePalette.mint: primaryColor = Colors.green.shade700; break;
        case AppThemePalette.darkVoid: primaryColor = Colors.indigo.shade900; break;
        default: primaryColor = Colors.blue;
      }
    }

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: baseMode(primary: primaryColor),
    );
  }
}
