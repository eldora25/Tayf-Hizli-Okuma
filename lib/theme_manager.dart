import 'package:flutter/material.dart';

enum AppThemePalette { deepPurple, oceanBlue, emeraldGreen, sunsetOrange, warmSepia }

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();
  ThemeManager._internal();

  ThemeMode _themeMode = ThemeMode.system;
  AppThemePalette _currentPalette = AppThemePalette.deepPurple;

  // Kitap Okuma Alanı Kişiselleştirme Ayarları
  double readerFontSize = 18.0;
  String readerFontFamily = 'monospace'; // monospace, serif, sans-serif
  Color? readerCustomTextColor;

  ThemeMode get themeMode => _themeMode;
  AppThemePalette get currentPalette => _currentPalette;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setPalette(AppThemePalette palette) {
    _currentPalette = palette;
    notifyListeners();
  }

  void updateReaderSettings(double size, String family, Color? color) {
    readerFontSize = size;
    readerFontFamily = family;
    readerCustomTextColor = color;
    notifyListeners();
  }

  Color get seedColor {
    switch (_currentPalette) {
      case AppThemePalette.deepPurple: return Colors.deepPurple;
      case AppThemePalette.oceanBlue: return const Color(0xFF0277BD);
      case AppThemePalette.emeraldGreen: return const Color(0xFF2E7D32);
      case AppThemePalette.sunsetOrange: return const Color(0xFFE65100);
      case AppThemePalette.warmSepia: return const Color(0xFF6D4C41);
    }
  }

  String getPaletteName(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.deepPurple: return 'Tayf Mor';
      case AppThemePalette.oceanBlue: return 'Okyanus Mavi';
      case AppThemePalette.emeraldGreen: return 'Zümrüt Yeşil';
      case AppThemePalette.sunsetOrange: return 'Ateş Turuncusu';
      case AppThemePalette.warmSepia: return 'Sıcak Sepya';
    }
  }

  ThemeData get lightTheme {
    final bool isSepia = _currentPalette == AppThemePalette.warmSepia;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        surface: isSepia ? const Color(0xFFFBF0D9) : null,
      ),
      scaffoldBackgroundColor: isSepia ? const Color(0xFFFBF0D9) : null,
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
    );
  }
}
