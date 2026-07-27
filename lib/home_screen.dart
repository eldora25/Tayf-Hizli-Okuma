import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reader_screen.dart';
import 'theme_manager.dart';
import 'book_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _multiFileTitleController = TextEditingController();
  final TextEditingController _multiFileContentController = TextEditingController();
  
  String _selectedFormat = 'EPUB';
  bool _isLoading = false;
  final String _buildNumber = "BUILD_NUMBER_PLACEHOLDER";

  final Map<String, String> _presetTexts = {
    "Hızlı Okuma Nedir?": "Hızlı okuma, göz kaslarını geliştirerek ve kelimeleri tek tek değil gruplar halinde görerek okuma hızını artırma tekniğidir.",
    "Odaklanma Egzersizi": "Gözlerimiz okuma yaparken sürekli geriye sıçrama eğilimindedir. RSVP tekniği kelimeleri tek bir noktada göstererek bu sıçramaları engeller."
  };

  Future<void> _fetchTextFromUrl(String url) async {
    if (url.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String rawBody = response.body;
        rawBody = rawBody.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>'), ' ');
        rawBody = rawBody.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>'), ' ');
        rawBody = rawBody.replaceAll(RegExp(r'<[^>]*>'), ' ');
        rawBody = rawBody.replaceAll(RegExp(r'&nbsp;'), ' ').replaceAll(RegExp(r'&amp;'), '&');
        String cleanText = rawBody.replaceAll(RegExp(r'\s+'), ' ').trim();
        setState(() => _textController.text = cleanText);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _addNewBookToLibrary() {
    if (_multiFileTitleController.text.isEmpty || _multiFileContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen kitap adı ve içeriğini doldurun!')));
      return;
    }
    setState(() {
      BookDatabase.instance.addBook(
        "${_multiFileTitleController.text}.${_selectedFormat.toLowerCase()}",
        _selectedFormat,
        _multiFileContentController.text,
      );
      _multiFileTitleController.clear();
      _multiFileContentController.clear();
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitap başarıyla Kitaplığıma eklendi!')));
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Yeni E-Kitap/Belge Yükle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _multiFileTitleController,
                  decoration: const InputDecoration(labelText: 'Kitap / Belge Adı'),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedFormat,
                  isExpanded: true,
                  items: ['EPUB', 'WORD', 'PDF', 'TXT'].map((String val) {
                    return DropdownMenuItem<String>(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) setModalState(() => _selectedFormat = newVal);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _multiFileContentController,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Kitap metnini veya bölüm içeriğini buraya ekleyin...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(onPressed: _addNewBookToLibrary, child: const Text('Kitaplığıma Ekle')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayBuild = _buildNumber.contains("PLACEHOLDER") ? "Local" : _buildNumber;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Tayf Eğitim Modu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('V1.$displayBuild | By: Tayfun YAMAK ©', style: const TextStyle(fontSize: 10)),
          ],
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      // YAN DRAWER MENÜ (KİTAPLARIM BÖLÜMÜ)
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: colorScheme.primaryContainer,
                child: Text('📚 Kitaplarım & Belgelerim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: BookDatabase.instance.getBooks().length,
                  itemBuilder: (context, index) {
                    final book = BookDatabase.instance.getBooks()[index];
                    return ListTile(
                      leading: Icon(Icons.menu_book, color: colorScheme.primary),
                      title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Format: ${book.format} | Sayfa: ${book.totalPages} | Kalınan: ${book.lastPage + 1}'),
                      trailing: const Icon(Icons.play_circle_fill, color: Colors.green),
                      onTap: () {
                        Navigator.pop(context); // Drawer'ı kapat
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(rawText: book.content, activeBook: book)));
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Çoklu Dosya/Kitap Ekle'),
                  onPressed: _showAddBookDialog,
                ),
              )
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Hazır Hızlı Okuma Egzersizleri', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _presetTexts.length,
                itemBuilder: (context, index) {
                  String title = _presetTexts.keys.elementAt(index);
                  return ListTile(
                    title: Text(title),
                    trailing: const Icon(Icons.bolt, color: Colors.amber),
                    onTap: () => _textController.text = _presetTexts[title]!,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('2. URL/Bağlantı Adresinden Eğitim Metni', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'https://...'))),
                IconButton(icon: const Icon(Icons.download), onPressed: () => _fetchTextFromUrl(_urlController.text)),
              ],
            ),
            const SizedBox(height: 16),
            Text('3. Manuel Eğitim Alanı (Kopyala/Yapıştır)', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            TextField(controller: _textController, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.model_training),
                label: const Text('Eğitim RSVP Başlat'),
                onPressed: () {
                  if (_textController.text.isEmpty) return;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(rawText: _textController.text)));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
