import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'book_database.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  // MainActivity.kt ile tam senkronize çalışan gerçek yerel kanal bağlantısı
  static const MethodChannel _storageChannel = MethodChannel('com.tayf.hizliokuma/storage');
  
  bool _isPicking = false;
  List<Map<String, String>> _pickedFilesResult = [];
  String _errorMessage = '';

  /// Gerçek Android Depolama Katmanını (Storage Access Framework) tetikleyen fonksiyon
  Future<void> _triggerAndroidNativeFilePicker() async {
    setState(() {
      _isPicking = true;
      _pickedFilesResult.clear();
      _errorMessage = '';
    });

    try {
      // Yerel Android döküman seçici penceresini patlatır
      final List<dynamic>? files = await _storageChannel.invokeMethod('pickMultipleFiles');
      
      if (files != null && files.isNotEmpty) {
        setState(() {
          for (var f in files) {
            if (f is Map) {
              _pickedFilesResult.add({
                'title': f['name']?.toString() ?? 'Bilinmeyen_Kitap.txt',
                'format': f['extension']?.toString().toUpperCase() ?? 'TXT',
                'content': f['content']?.toString() ?? '',
              });
            }
          }
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = "Yerel kanal hatası: ${e.message}\nWeb/Masaüstü simülasyonu aktif edildi.";
        // Masaüstü veya Web test ortamlarında derleme çökmesini önlemek için koruyucu geri dönüş
        _pickedFilesResult = [
          {"title": "Ornek_Cihaz_Dosyasi.epub", "format": "EPUB", "content": "Raskolnikov sıcak bir Temmuz ayında tavan arasındaki odasından çıktı. Yerel Android depolama simülasyon veri katmanı."},
          {"title": "Okuma_Belgesi.txt", "format": "TXT", "content": "Hızlı okuma antrenman modülleri kalınan sayfaya göre kararlı bir biçimde hafızada tutulur."}
        ];
      });
    } finally {
      setState(() => _isPicking = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Kullanıcı sayfaya girdiği an doğrudan Android yerel klasör penceresini tetikliyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAndroidNativeFilePicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cihaz Hafızasından Seç'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerçek Dizin Çözümleyici Entegrasyonu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Android sistem arayüzünde dosyaların üzerine basılı tutarak birden fazla kitap (*.epub, *.txt, *.pdf, *.docx) seçebilirsiniz.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),
            
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.amber, fontSize: 11)),
              ),
              
            Expanded(
              child: _isPicking
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Android Sistem Deposu Açılıyor...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : _pickedFilesResult.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_shared, size: 48, color: colorScheme.outline),
                              const SizedBox(height: 12),
                              const Text('Herhangi bir gerçek dosya seçilmedi.'),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Dosya Seçiciyi Tekrar Aç'),
                                onPressed: _triggerAndroidNativeFilePicker,
                              )
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _pickedFilesResult.length,
                          itemBuilder: (context, idx) {
                            final file = _pickedFilesResult[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(file['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('Format: ${file['format']} | Okuma Durumu: Başarılı'),
                                trailing: const Icon(Icons.file_present, color: Colors.amber),
                              ),
                            );
                          },
                        ),
            ),
            const Divider(),
            
            if (_pickedFilesResult.isNotEmpty && !_isPicking)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_to_photos),
                    label: Text('${_pickedFilesResult.length} Adet Kitabı Uygulamaya Yükle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // Seçilen gerçek dosyaları veritabanına kararlı biçimde yazar
                      BookDatabase.instance.addMultipleBooks(List.from(_pickedFilesResult));
                      Navigator.pop(context, true); 
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
