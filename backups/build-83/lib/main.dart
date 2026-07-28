import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'theme_manager.dart';
import 'book_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uygulama başlamadan önce kalıcı hafızadaki tema, font, kitap ve kalınan yerleri yükle
  await ThemeManager.instance.init();
  await BookDatabase.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeManager içindeki notifyListeners() çalıştığında arayüzü anında günceller
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
