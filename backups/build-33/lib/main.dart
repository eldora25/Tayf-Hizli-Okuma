import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'theme_manager.dart';

void main() {
  runApp(const TayfHizliOkumaApp());
}

class TayfHizliOkumaApp extends StatelessWidget {
  const TayfHizliOkumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Tayf Hızlı Okuma',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeManager.instance.themeMode,
          theme: ThemeManager.instance.lightTheme,
          darkTheme: ThemeManager.instance.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
