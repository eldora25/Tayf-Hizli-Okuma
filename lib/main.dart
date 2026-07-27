import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const TayfHizliOkumaApp());
}

class TayfHizliOkumaApp extends StatelessWidget {
  const TayfHizliOkumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Hızlı Okuma',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
