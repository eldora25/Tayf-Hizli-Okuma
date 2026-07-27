import 'package:flutter/material.dart';

enum AppThemePalette { classic, amber, darkVoid, mint }

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();
  ThemeManager._internal();

  ThemeMode themeMode = ThemeMode.light;
  AppThemePalette currentPalette = AppThemePalette.classic;
  
  double readerFontSize = 18.0;
  String readerFontFamily = 'sans-serif';
  Color readerTextColor = Colors.red;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners(); // Tema değiştiğinde tüm ekranları anında uyarır
  }

  void setPalette(AppThemePalette palette) {
    currentPalette = palette;
    notifyListeners();
  }

  void updateReaderSettings(double size, String fontFamily, Color textColor) {
    readerFontSize = size;
    readerFontFamily = fontFamily;
    readerTextColor = textColor;
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

  // ORP (Odak) harfinin normalden çok daha parlak (fosforlu/canlı) görünmesini sağlar
  Color getVibrantOrpColor() {
    if (readerTextColor == Colors.red) return const Color(0xFFFF1744); // Neon Kırmızı
    if (readerTextColor == Colors.amber) return const Color(0xFFFF9100); // Parlak Turuncu
    if (readerTextColor == Colors.blue) return const Color(0xFF2979FF); // Elektrik Mavisi
    if (readerTextColor == Colors.green) return const Color(0xFF00E676); // Fosforlu Yeşil
    return readerTextColor;
  }

  Color getReaderBackgroundColor() {
    if (themeMode == ThemeMode.dark) {
      return const Color(0xFF121212);
    }
    switch (currentPalette) {
      case AppThemePalette.amber: return const Color(0xFFFDF6E3);
      case AppThemePalette.mint: return const Color(0xFFE8F5E9);
      case AppThemePalette.darkVoid: return const Color(0xFF1A1A24);
      default: return Colors.white;
    }
  }

  Color getReaderTextColor() {
    if (themeMode == ThemeMode.dark) {
      return const Color(0xFFE5E5E5);
    }
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
      colorScheme: baseMode(primary: primaryColor),
    );
  }
}
