import 'package:flutter/material';
import 'book_database.dart';
import 'file_picker_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayf Hızlı Okuma',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.navigateInit();
    _loadInitialData();
  }

  /// Uygulama ilk açıldığında dahili varlıkları (assets) yükler ve listeyi tazeler
  Future<void> _loadInitialData() async {
    await BookDatabase.instance.loadDefaultAssets();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = BookDatabase.instance.getBooks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kütüphanem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // İçe aktarma ekranından dönüş değeri (true) kontrol edilir
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilePickerScreen()),
              );

              // Eğer yeni kitap yüklendiyse UI'ın güncellenmesi sağlanır
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
              ? const Center(child: Text('Kütüphanede kitap bulunamadı.'))
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return ListTile(
                      leading: const Icon(Icons.menu_book, color: Colors.blue),
                      title: Text(book.title),
                      subtitle: Text('Format: ${book.format} | Sayfa: ${book.totalPages}'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${book.title} seçildi.')),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
