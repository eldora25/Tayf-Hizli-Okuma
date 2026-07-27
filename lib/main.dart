import 'package:flutter/material.dart';
import 'home_screen.dart'; // Sizin kendi tasarımınız olan ana arayüz dosyasına bağlanır

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Hızlı Okuma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Doğrudan kendi profesyonel arayüzünüze yönlendirir
    );
  }
}
