import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'theme_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder, ThemeManager içindeki notifyListeners() tetiklendiğinde uygulamayı yeniden çizer
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Tayf Hızlı Okuma',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeManager.instance.themeMode,
          theme: ThemeManager.instance.getThemeData(false),
          darkTheme: ThemeManager.instance.getThemeData(true),
          home: const HomeScreen(),
        );
      },
    );
  }
}
