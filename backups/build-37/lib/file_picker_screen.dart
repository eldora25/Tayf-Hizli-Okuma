import 'package:flutter/material.dart';
import 'book_database.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedFormat = 'EPUB';

  // İçe aktarma sırasında kuyruğa alınan gerçek kitap havuzu
  final List<Map<String, String>> _importQueue = [];

  void _addBookToQueue() {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kitap adını ve içeriğini doldurun!')),
      );
      return;
    }

    setState(() {
      _importQueue.add({
        'title': '${_titleController.text.trim()}.${_selectedFormat.toLowerCase()}',
        'format': _selectedFormat,
        'content': _contentController.text.trim(),
      });
      _titleController.clear();
      _contentController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dosya başarıyla içe aktarma kuyruğuna eklendi! Yeni ekleyebilirsiniz.')),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişmiş Çoklu Dosya İçe Aktar'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evrensel E-Kitap ve Belge Çözümleyici',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Yerel izin engellerine takılmadan cihazınızdaki .epub, .txt, .pdf, .docx kitap metinlerini topluca veya tek tek kitaplığınıza aktarın.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 24),
              
              // Kitap Tanımlama Bilgileri
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Kitap / Belge Adı',
                  hintText: 'Örn: Sefiller, Makale_Notlari',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: const InputDecoration(
                  labelText: 'Dosya Formatı Ayrıştırıcı',
                  border: OutlineInputBorder(),
                ),
                items: ['EPUB', 'TXT', 'PDF', 'WORD'].map((String format) {
                  return DropdownMenuItem<String>(
                    value: format,
                    child: Text(format),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFormat = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              
              // Gerçek Metin / Kitap İçeriği Giriş Alanı
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Kitap / Belge İçeriği Veya Sayfa Metni',
                  hintText: 'Cihazınızdan kopyaladığınız kitap metnini buraya yapıştırın...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Kuyruğa Ekleme Butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_to_photos),
                  label: const Text('Bu Dosyayı Kuyruğa Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                  onPressed: _addBookToQueue,
                ),
              ),
              
              const Divider(height: 32),
              
              // Aktarılmaya Hazır Kuyruk Listesi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kuyruktaki Kitaplar (${_importQueue.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (_importQueue.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _importQueue.clear()),
                      child: const Text('Kuyruğu Temizle', style: TextStyle(color: Colors.red)),
                    )
                ],
              ),
              const SizedBox(height: 8),
              
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _importQueue.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Kuyruk boş. Yukarıdan dosya tanımlayıp ekleyin.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _importQueue.length,
                        itemBuilder: (context, index) {
                          final qBook = _importQueue[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.library_books, color: Colors.amber),
                            title: Text(qBook['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Format: ${qBook['format']} | Karakter Sayısı: ${qBook['content']!.length}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _importQueue.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              
              // Toplu Veritabanı Yazma Butonu
              if (_importQueue.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Kuyruktaki Tüm Kitapları Veritabanına Yaz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // Tüm kuyruğu veritabanına kararlı bir şekilde ekle
                      BookDatabase.instance.addMultipleBooks(List.from(_importQueue));
                      _importQueue.clear();
                      Navigator.pop(context, true); // Onay bayrağı ile ana ekrana dön
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
