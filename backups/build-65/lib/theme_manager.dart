import 'package:flutter/material.dart';

enum AppThemePalette { classic, amber, darkVoid, mint }

class ThemeManager {
  static final ThemeManager instance = ThemeManager._internal();
  ThemeManager._internal();

  ThemeMode themeMode = ThemeMode.light;
  AppThemePalette currentPalette = AppThemePalette.classic;
  
  double readerFontSize = 18.0;
  String readerFontFamily = 'sans-serif';
  Color readerTextColor = Colors.red;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
  }

  void setPalette(AppThemePalette palette) {
    currentPalette = palette;
  }

  void updateReaderSettings(double size, String fontFamily, Color textColor) {
    readerFontSize = size;
    readerFontFamily = fontFamily;
    readerTextColor = textColor;
  }

  String getPaletteName(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.classic: return "Klasik";
      case AppThemePalette.amber: return "Kehribar";
      case AppThemePalette.darkVoid: return "Uzay";
      case AppThemePalette.mint: return "Nane";
    }
  }

  /// Aktif temaya ve mod ayarlarına göre okuma arka plan rengini belirler
  Color getReaderBackgroundColor() {
    if (themeMode == ThemeMode.dark) {
      return const Color(0xFF121212);
    }
    switch (currentPalette) {
      case AppThemePalette.amber: return const Color(0xFFFDF6E3);
      case AppThemePalette.mint: return const Color(0xFFE8F5E9);
      case AppThemePalette.darkVoid: return const Color(0xFF1C1C1E);
      default: return Colors.white;
    }
  }

  /// Aktif temaya göre okuma metni (highlight dışı) rengini belirler
  Color getReaderTextColor() {
    if (themeMode == ThemeMode.dark) {
      return const Color(0xFFE5E5E5);
    }
    switch (currentPalette) {
      case AppThemePalette.darkVoid: return const Color(0xFFE5E5E5);
      default: return const Color(0xFF2C3E50);
    }
  }

  /// Seçili temaya göre Flutter ana temasını döndürür
  ThemeData getThemeData(bool isDark) {
    final baseMode = isDark ? ColorScheme.dark : ColorScheme.light;
    Color primaryColor = Colors.blue;

    if (!isDark) {
      switch (currentPalette) {
        case AppThemePalette.amber:
          primaryColor = Colors.amber.shade900;
          break;
        case AppThemePalette.mint:
          primaryColor = Colors.green.shade700;
          break;
        case AppThemePalette.darkVoid:
          primaryColor = Colors.indigo.shade900;
          break;
        default:
          primaryColor = Colors.blue;
      }
    }

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: baseMode(
        primary: primaryColor,
      ),
    );
  }
}
