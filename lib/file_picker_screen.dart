import 'package:flutter/material';
import 'book_database.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({Key? key}) : super(key: key);

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  final List<Map<String, dynamic>> _pickedFilesResult = [];
  bool _isSaving = false;

  /// Dosya seçici tetiklendiğinde veya taklit edildiğinde listeye mock veri ekleme simülasyonu
  void _addMockFileForDemo() {
    // Örnek dosya byte akış yapısı
    setState(() {
      _pickedFilesResult.add({
        'title': 'Dışarıdan Alınan Kitap Örneği',
        'format': 'TXT',
        'bytes': Uri.parse('data:text/plain;charset=utf-8,Bu%20bir%20deneme%20metnidir.').data!.contentAsBytes(),
      });
    });
  }

  /// "Kitabı Uygulamaya Yükle" butonunun asenkron beklemeyi yapıp ana sayfaya güvenle döndüğü işlev
  Future<void> _handleSaveBooks() async {
    if (_pickedFilesResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce yüklenecek bir kitap seçin.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Veritabanına asenkron yazma işlemi bekleniyor
      await BookDatabase.instance.addMultipleBooks(List.from(_pickedFilesResult));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitaplar başarıyla kütüphaneye eklendi.')),
        );
        // Kitaplar başarıyla eklendikten sonra listenin yenilenmesi için ana ekrana başarılı dönüt gönderilir
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme sırasında hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap İçe Aktar'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                stretch: true,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addMockFileForDemo,
                    icon: const Icon(Icons.file_open),
                    label: const Text('Cihazdan Kitap Seç (EPUB/TXT)'),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _pickedFilesResult.isEmpty
                        ? const Center(child: Text('Henüz dosya seçilmedi.'))
                        : ListView.builder(
                            itemCount: _pickedFilesResult.length,
                            itemBuilder: (context, index) {
                              final file = _pickedFilesResult[index];
                              return ListTile(
                                leading: const Icon(Icons.book),
                                title: Text(file['title'] ?? ''),
                                subtitle: Text(file['format'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _pickedFilesResult.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _handleSaveBooks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kitabı Uygulamaya Yükle'),
                  ),
                ],
              ),
            ),
    );
  }
}
